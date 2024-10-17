class MoviesController < ApplicationController
  def index
    @movies = Movie.all
    @movie = Movie.new
  end

  def create
    @movie = Movie.new(movie_params)
    if @movie.save
      flash[:notice] = "Movie created successfully!"
      redirect_to movies_path
    else
      flash[:alert] = "Error creating movie."
      render :index
    end
  end

  private

  def movie_params
    params.require(:movie).permit(:title, :director, :release_year)
  end
end