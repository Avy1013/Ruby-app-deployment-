# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.2
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails


# Install base packages including PostgreSQL client
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile
RUN gem install rails

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]



# Expose the port the app runs on
EXPOSE 3000

# Start the server by default
# CMD ["rails", "server", "-b", "0.0.0.0"]
# CMD ["./bin/rails", "server", "-b", "0.0.0.0" && rails db:migrate RAILS_ENV=production]


# this line run easily when running with docker compose up command
CMD sh -c "rails db:migrate RAILS_ENV=production && rails db:seed RAILS_ENV=production && rails server -b 0.0.0.0"

# all the commands below are a effort to run it in a minikube setup
# Copy the entrypoint script into the container
# COPY docker-entrypoint.sh /usr/bin/docker-entrypoint.sh

# # Make the entrypoint script executable
# # RUN chmod +x /usr/bin/docker-entrypoint.sh
# CMD sh -c "chmod +x /usr/bin/docker-entrypoint.sh" 
# # Use the entrypoint script
# ENTRYPOINT ["/usr/bin/docker-entrypoint.sh"]








# Step 1: Use the Ruby slim image to minimize size


# syntax = docker/dockerfile:1

# # Step 1: Use the Ruby slim image to minimize size
# ARG RUBY_VERSION=3.2.2
# FROM ruby:$RUBY_VERSION-slim AS base

# # Step 2: Set working directory inside the container
# WORKDIR /rails

# # Step 3: Install dependencies
# RUN apt-get update -qq && \
#     apt-get install --no-install-recommends -y \
#     build-essential \
#     curl \
#     libpq-dev \
#     nodejs \
#     postgresql-client \
#     && rm -rf /var/lib/apt/lists/*

# # Step 4: Set environment variables
# ENV RAILS_ENV=production \
#     BUNDLE_PATH="/usr/local/bundle" \
#     BUNDLE_WITHOUT="development test"

# # Step 5: Install bundler and required gems
# COPY Gemfile Gemfile.lock ./
# RUN gem install bundler:2.4.0 && bundle install --jobs=4 --retry=3

# # Step 6: Install Rails manually
# RUN gem install rails

# # Step 7: Copy application code
# COPY . .



# # Step 10: Expose port 3000 for the Rails app
# EXPOSE 3000



# # Step 11: Start the Rails server by default
# CMD ["rails", "server", "-b", "0.0.0.0"]
