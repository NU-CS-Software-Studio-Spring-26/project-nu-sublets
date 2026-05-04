class User < ApplicationRecord
  NORTHWESTERN_EMAIL_DOMAINS = %w[u.northwestern.edu northwestern.edu ads.northwestern.edu].freeze

  # Authentication (you'll want to add has_secure_password if using bcrypt)
  # has_secure_password

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true

  # Associations
  has_many :sublet_listings, dependent: :destroy
  # has_many :applications, dependent: :destroy

  # Scopes
  scope :active, -> { where(active: true) }

  # Class Methods (CRUD Operations)
  def self.create_user(params)
    user = new(params)
    if user.save
      { success: true, user: user, message: "User created successfully" }
    else
      { success: false, errors: user.errors.full_messages }
    end
  end

  def self.find_by_email_or_id(identifier)
    return find(identifier) if identifier.is_a?(Integer) || identifier.match?(/^\d+$/)
    find_by(email: identifier)
  end

  def self.search(query)
    where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%")
  end

  def self.northwestern_email?(email)
    domain = email.to_s.downcase.split("@").last
    NORTHWESTERN_EMAIL_DOMAINS.include?(domain)
  end

  # Instance Methods
  def update_profile(params)
    if update(params)
      { success: true, message: "Profile updated successfully" }
    else
      { success: false, errors: errors.full_messages }
    end
  end

  def soft_delete
    update(active: false, deleted_at: Time.current)
  end

  def reactivate
    update(active: true, deleted_at: nil)
  end

  def hard_delete
    sublet_listings.destroy_all
    destroy
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    name.present? ? name : email.split("@").first
  end

  def active_listings_count
    sublet_listings.available.count
  end

  def total_listings_count
    sublet_listings.count
  end
end
