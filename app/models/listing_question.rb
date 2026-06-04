class ListingQuestion < ApplicationRecord
  MAX_BODY_LENGTH = 500
  MAX_ANSWER_LENGTH = 1_000

  belongs_to :sublet_listing
  belongs_to :user

  before_validation :normalize_text_fields

  validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
  validates :answer, length: { maximum: MAX_ANSWER_LENGTH }, allow_blank: true
  validates_no_profanity_in :body, :answer

  def answered?
    answer.present?
  end

  private

  def normalize_text_fields
    self.body = normalize_text(body)
    self.answer = normalize_text(answer)
    self.answered_at = answer.present? ? (answered_at || Time.current) : nil
  end

  def normalize_text(value)
    value.to_s.gsub(/[[:cntrl:]]/, " ").squish.presence
  end
end
