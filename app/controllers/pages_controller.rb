class PagesController < ApplicationController
  layout false

  def home; end

  def listing; end

  def search_results; end

  def post_sublet; end

  def profile; end

  def login; end

  def submit_sublet
    redirect_to listing_path
  end
end
