class User < ApplicationRecord
  NORTHWESTERN_EMAIL_DOMAINS = %w[u.northwestern.edu northwestern.edu ads.northwestern.edu].freeze
  MINIMUM_PASSWORD_LENGTH = 8

  attr_accessor :require_password

  has_secure_password validations: false

  # Validations
  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validate :northwestern_email_domain
  validate :password_presence, if: :require_password?
  validate :password_requirements
  validate :password_confirmation_matches
  validate :profile_photo_must_be_image

  # Associations
  has_many :sublet_listings, dependent: :destroy
  has_one_attached :profile_photo
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

  def self.from_omniauth(auth)
    email = auth.dig("info", "email").to_s.downcase
    return unless northwestern_email?(email)

    user = find_by(provider: auth["provider"], uid: auth["uid"]) || find_by(email: email)
    user ||= new(email: email)

    user.assign_attributes(
      email: email,
      name: auth.dig("info", "name").presence || user.name || email.split("@").first,
      provider: auth["provider"],
      uid: auth["uid"],
      profile_photo_url: auth.dig("info", "image").presence || user.profile_photo_url,
      active: true
    )
    user.save!
    user
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

  private

  def normalize_email
    self.email = email.to_s.strip.downcase if email.present?
  end

  def northwestern_email_domain
    return if email.blank? || self.class.northwestern_email?(email)

    errors.add(:email, "must be a Northwestern email")
  end

  def password_presence
    errors.add(:password, "can't be blank") if password.blank?
  end

  def password_requirements
    return if password.blank?

    if password.length < MINIMUM_PASSWORD_LENGTH
      errors.add(:password, "must be at least #{MINIMUM_PASSWORD_LENGTH} characters")
    end
  end

  def password_confirmation_matches
    return if password.blank? || password == password_confirmation

    errors.add(:password_confirmation, "doesn't match Password")
  end

  def require_password?
    ActiveModel::Type::Boolean.new.cast(require_password)
  end

  def profile_photo_must_be_image
    return unless profile_photo.attached?
    return if profile_photo.content_type.in?(%w[image/png image/jpeg image/webp image/gif])

    errors.add(:profile_photo, "must be a PNG, JPG, WebP, or GIF image")
  end
end
