class ListingQuestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: :create
  before_action :set_question, only: %i[update destroy]

  def create
    if @listing.user_id == current_user.id
      redirect_to sublet_listing_path(@listing), alert: "You cannot ask a question on your own listing."
      return
    end

    question = @listing.listing_questions.new(question_params)
    question.user = current_user

    if question.save
      redirect_to sublet_listing_path(@listing, anchor: "questions"), notice: "Question posted."
    else
      redirect_to sublet_listing_path(@listing, anchor: "questions"), alert: question.errors.full_messages.to_sentence
    end
  end

  def update
    unless listing_owner?
      redirect_to sublet_listing_path(@question.sublet_listing), alert: "Only the listing owner can answer questions."
      return
    end

    if @question.update(answer_params)
      redirect_to sublet_listing_path(@question.sublet_listing, anchor: "questions"), notice: "Answer posted."
    else
      redirect_to sublet_listing_path(@question.sublet_listing, anchor: "questions"), alert: @question.errors.full_messages.to_sentence
    end
  end

  def destroy
    unless listing_owner? || @question.user_id == current_user.id
      redirect_to sublet_listing_path(@question.sublet_listing), alert: "You can only delete your own questions."
      return
    end

    listing = @question.sublet_listing
    @question.destroy
    redirect_to sublet_listing_path(listing, anchor: "questions"), notice: "Question deleted."
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
end
