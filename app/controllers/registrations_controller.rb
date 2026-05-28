class RegistrationsController < ApplicationController
  layout false

  def new
    redirect_to profile_path, notice: "You are already logged in." if user_signed_in?
  end

  def create
    redirect_to login_path, alert: "Use Google sign-in with your Northwestern account to create an account."
  end
end
