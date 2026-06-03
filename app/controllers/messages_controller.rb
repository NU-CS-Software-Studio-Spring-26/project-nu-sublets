class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    message = @conversation.messages.new(message_params)
    message.sender = current_user

    if message.save
      respond_to do |format|
        format.html { redirect_to conversation_path(@conversation) }
        format.json { render json: { id: message.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { redirect_to conversation_path(@conversation), alert: message.errors.full_messages.to_sentence }
        format.json { render json: { errors: message.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  end

  def message_params
    params.require(:message).permit(:body)
  end
end
