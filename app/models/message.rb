class Message < ApplicationRecord
  MAX_BODY_LENGTH = 1_000

  belongs_to :conversation
  belongs_to :sender, class_name: "User", inverse_of: :messages

  before_validation :normalize_body
  after_create_commit :broadcast_to_conversation

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validate :sender_is_conversation_participant

  private

  def normalize_body
    self.body = body.to_s.gsub(/[[:cntrl:]]/, " ").squish.presence
  end

  def sender_is_conversation_participant
    return if conversation&.participant?(sender)

    errors.add(:sender, "must be a conversation participant")
  end

  def broadcast_to_conversation
    ConversationChannel.broadcast_to(
      conversation,
      {
        id: id,
        sender_id: sender_id,
        sender_name: sender.display_name,
        body: body,
        created_at: created_at.strftime("%b %-d, %Y %-l:%M %p")
      }
    )
  end
end
