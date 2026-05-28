require "pagy"

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :user_signed_in?, :google_oauth_configured?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user&.confirmed?
  end

  def google_oauth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  def authenticate_user!
    return if user_signed_in?

    respond_to do |format|
      format.html { redirect_to login_path, alert: "Log in with your Northwestern email first." }
      format.json { render json: { error: "You must be logged in." }, status: :unauthorized }
    end
  end
end
