class PagesController < ApplicationController
  layout false

  def home; end

  def listing; end

  def search_results; end

  def post_sublet; end

<<<<<<< HEAD
  def profile; end
=======
  def submit_sublet
    redirect_to listing_path
  end
>>>>>>> e4fa85c ([feat] routed post sublet)
end
