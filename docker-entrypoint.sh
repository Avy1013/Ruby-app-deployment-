#!/bin/sh

# Run database migrations
echo "Running database migrations..."
rails db:migrate RAILS_ENV=production || { echo 'Migration failed! Exiting...'; exit 1; }

# Run database seeding
echo "Seeding the database..."
rails db:seed RAILS_ENV=production || { echo 'Seeding failed! Exiting...'; exit 1; }

# Start the Rails server
echo "Starting Rails server..."
exec rails server -b 0.0.0.0
