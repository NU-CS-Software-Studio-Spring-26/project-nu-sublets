class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User", inverse_of: :initiated_conversations
  belongs_to :recipient, class_name: "User", inverse_of: :received_conversations
  belongs_to :sublet_listing, optional: true
  has_many :messages, dependent: :destroy

  before_validation :assign_conversation_key

  validates :initiator, :recipient, :conversation_key, presence: true
  validates :conversation_key, uniqueness: true
  validate :participants_are_distinct

  scope :involving, ->(user) {
    where("initiator_id = :user_id OR recipient_id = :user_id", user_id: user.id)
  }

  def self.between(user, other_user, listing: nil)
    key = build_conversation_key(user.id, other_user.id, listing&.id)
    find_or_initialize_by(conversation_key: key) do |conversation|
      conversation.initiator = user
      conversation.recipient = other_user
      conversation.sublet_listing = listing
    end
  end

  def self.build_conversation_key(first_user_id, second_user_id, listing_id = nil)
    participant_ids = [ first_user_id, second_user_id ].map(&:to_i).sort
    listing_key = listing_id.present? ? listing_id.to_i : "direct"

    [ participant_ids.join("-"), listing_key ].join(":")
  end

  def participant?(user)
    user.present? && [ initiator_id, recipient_id ].include?(user.id)
  end

  def other_participant(user)
    return recipient if user&.id == initiator_id

    initiator if user&.id == recipient_id
  end

  private

  def assign_conversation_key
    return if initiator_id.blank? || recipient_id.blank?

    self.conversation_key = self.class.build_conversation_key(initiator_id, recipient_id, sublet_listing_id)
  end

  def participants_are_distinct
    return if initiator_id.blank? || recipient_id.blank? || initiator_id != recipient_id

    errors.add(:recipient, "must be a different student")
  end

end
