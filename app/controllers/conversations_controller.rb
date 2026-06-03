class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: :show

  def index
    @conversations = current_user.conversations.includes(:initiator, :recipient, :sublet_listing, messages: :sender).to_a
    @conversations.sort_by! { |conversation| conversation.messages.max_by(&:created_at)&.created_at || conversation.created_at }
    @conversations.reverse!
  end

  def show
    @messages = @conversation.messages.includes(:sender).order(:created_at)
    @message = Message.new
    @other_participant = @conversation.other_participant(current_user)
  end

  def create
    recipient = User.find(params[:recipient_id])
    listing = SubletListing.find_by(id: params[:sublet_listing_id])
    conversation = Conversation.between(current_user, recipient, listing: listing)

    if conversation.save
      redirect_to conversation_path(conversation)
    else
      redirect_back fallback_location: conversations_path, alert: conversation.errors.full_messages.to_sentence
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  end
end
