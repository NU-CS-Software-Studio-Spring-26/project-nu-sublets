class PagesController < ApplicationController
  layout false
  before_action :authenticate_user!, only: %i[profile submit_sublet]

  def home; end

  def listing; end

  def search_results; end

  def post_sublet; end

  def profile; end

  def login
    redirect_to profile_path if user_signed_in?
  end

  def submit_sublet
    redirect_to listing_path
  end
end
