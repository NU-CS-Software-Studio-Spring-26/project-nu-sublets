class ListingQuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: :create
  before_action :set_question, only: %i[update destroy]

  def create
    if @listing.user_id == current_user.id
      respond_with_questions_error("You cannot ask a question on your own listing.", anchor: false)
      return
    end

    @listing_question = @listing.listing_questions.new(question_params)
    @listing_question.user = current_user

    if @listing_question.save
      respond_with_questions_success("Question posted.")
    else
      respond_with_questions_error(@listing_question.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end
  end

  def update
    unless listing_owner?
      @listing = @question.sublet_listing
      respond_with_questions_error("Only the listing owner can answer questions.", anchor: false, status: :forbidden)
      return
    end

    @listing = @question.sublet_listing

    if @question.update(answer_params)
      respond_with_questions_success("Answer posted.")
    else
      respond_with_questions_error(@question.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end
  end

  def destroy
    unless listing_owner? || @question.user_id == current_user.id
      @listing = @question.sublet_listing
      respond_with_questions_error("You can only delete your own questions.", anchor: false, status: :forbidden)
      return
    end

    @listing = @question.sublet_listing
    @question.destroy
    respond_with_questions_success("Question deleted.")
  end

  private

  def set_listing
    @listing = SubletListing.find(params[:sublet_listing_id])
  end

  def set_question
    @question = ListingQuestion.includes(:sublet_listing).find(params[:id])
  end

  def listing_owner?
    @question.sublet_listing.user_id == current_user.id
  end

  def question_params
    params.require(:listing_question).permit(:body)
  end

  def answer_params
    params.require(:listing_question).permit(:answer)
  end

  def respond_with_questions_success(message)
    respond_to do |format|
      format.html { redirect_to sublet_listing_path(@listing, anchor: "questions"), notice: message }
      format.turbo_stream do
        @listing_question = ListingQuestion.new
        flash.now[:notice] = message
        prepare_listing_questions_context
        render_questions_turbo_stream
      end
    end
  end

  def respond_with_questions_error(message, status: :unprocessable_entity, anchor: true)
    respond_to do |format|
      format.html do
        location = anchor ? sublet_listing_path(@listing, anchor: "questions") : sublet_listing_path(@listing)
        redirect_to location, alert: message
      end
      format.turbo_stream do
        flash.now[:alert] = message
        prepare_listing_questions_context
        render_questions_turbo_stream(status:)
      end
    end
  end

  def prepare_listing_questions_context
    @listing_host = @listing.user || User.new(name: "Listing Host")
    @listing_questions = @listing.listing_questions.includes(:user).order(created_at: :desc).to_a

    if @question.present?
      question_index = @listing_questions.index { |question| question.id == @question.id }
      @listing_questions[question_index] = @question if question_index
    end

    @listing_question ||= ListingQuestion.new
    @listing_report = ListingReport.new
  end

  def render_questions_turbo_stream(status: :ok)
    render turbo_stream: turbo_stream.replace(
      "listing_questions",
      partial: "pages/listing_questions_section"
    ), status:
  end
end
