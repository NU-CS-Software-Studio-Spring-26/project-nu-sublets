class OnboardingController < ApplicationController
  layout false

  skip_before_action :enforce_terms_acceptance
  before_action :authenticate_user!
  before_action :redirect_if_terms_already_accepted, only: :terms

  def terms; end

  def accept_terms
    if params[:terms_accepted] == "1"
      current_user.update!(terms_accepted_at: Time.current)
      session.delete(:requires_terms_acceptance)
      redirect_to profile_path, notice: "Welcome to NU Sublets!"
    else
      flash.now[:alert] = "You must accept the Terms and Community Guidelines to continue."
      render :terms, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_terms_already_accepted
    redirect_to profile_path if current_user.terms_accepted_at.present?
  end
end
