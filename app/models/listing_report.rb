class ListingReport < ApplicationRecord
  MAX_DESCRIPTION_LENGTH = 1_000
  STATUSES = %w[open reviewed dismissed].freeze

  belongs_to :sublet_listing
  belongs_to :user

  before_validation :normalize_description

  validates :description, presence: true, length: { maximum: MAX_DESCRIPTION_LENGTH }
  validates :status, inclusion: { in: STATUSES }
  validates_no_profanity_in :description

  private

  def normalize_description
    self.description = description.to_s.gsub(/[[:cntrl:]]/, " ").squish.presence
  end
end
