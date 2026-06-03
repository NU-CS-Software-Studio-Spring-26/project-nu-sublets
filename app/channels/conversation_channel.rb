class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = current_user.conversations.find_by(id: params[:conversation_id])
    reject unless conversation

    stream_for conversation
  end
end
