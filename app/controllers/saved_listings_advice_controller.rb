class SavedListingsAdviceController < ApplicationController
  before_action :authenticate_user!

  def create
    advice = SavedListingsAdvisor.new(
      preferences: params[:preferences],
      listings: params[:listings]
    ).advise

    render json: { advice: advice }
  rescue SavedListingsAdvisor::ValidationError => error
    render json: { error: error.message }, status: :unprocessable_entity
  rescue SavedListingsAdvisor::AdviceUnavailable => error
    render json: { error: error.message, unavailable: true }
  end
end
