class SubletListing < ApplicationRecord
  # Associations
  belongs_to :user
  
  # Validations
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :address, presence: true
  validates :available_from, presence: true
  validates :available_until, presence: true
  validates :bedrooms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bathrooms, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Custom validations
  validate :available_until_after_available_from
  validate :available_from_not_in_past
  
  # Scopes
  scope :available, -> { where('available_until >= ?', Date.current) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }
  scope :by_bedrooms, ->(count) { where(bedrooms: count) }
  scope :furnished_only, -> { where(furnished: true) }
  scope :pets_allowed_only, -> { where(pets_allowed: true) }
  scope :covering_date_range, ->(move_in, move_out) { where('available_from <= ? AND available_until >= ?', move_in, move_out) }
  
  # Methods
  def available_duration_days
    (available_until - available_from).to_i
  end
  
  def available_months
    available_duration_days / 30.0
  end
  
  def price_per_bedroom
    return price if bedrooms.zero?
    price / bedrooms
  end
  
  def currently_available?
    Date.current.between?(available_from, available_until)
  end
  
  def short_address
    address.split(',').first
  end
  
  # Class Methods (CRUD Operations)
  def self.create_listing(user, params)
    listing = user.sublet_listings.new(params)
    if listing.save
      { success: true, listing: listing, message: "Listing created successfully" }
    else
      { success: false, errors: listing.errors.full_messages }
    end
  end
  
  def self.search_listings(filters = {})
    listings = all
    
    listings = listings.where('title ILIKE ? OR description ILIKE ? OR address ILIKE ?', 
                             "%#{filters[:query]}%", "%#{filters[:query]}%", "%#{filters[:query]}%") if filters[:query].present?
    
    listings = listings.by_price_range(filters[:min_price], filters[:max_price]) if filters[:min_price] && filters[:max_price]
    listings = listings.by_bedrooms(filters[:bedrooms]) if filters[:bedrooms].present?
    listings = listings.furnished_only if filters[:furnished] == true
    listings = listings.pets_allowed_only if filters[:pets_allowed] == true
    listings = listings.available if filters[:available_only] == true

    move_in = normalize_filter_date(filters[:move_in] || filters["move-in"])
    move_out = normalize_filter_date(filters[:move_out] || filters["move-out"])

    if move_in && move_out
      listings = listings.covering_date_range(move_in, move_out)
    elsif move_in
      listings = listings.where('available_until >= ?', move_in)
    elsif move_out
      listings = listings.where('available_from <= ?', move_out)
    end
    
    listings
  end
  
  def self.find_available_listings
    available.order(:price)
  end
  
  # Instance Methods
  def update_listing(params)
    if update(params)
      { success: true, message: "Listing updated successfully" }
    else
      { success: false, errors: errors.full_messages }
    end
  end
  
  def mark_unavailable
    update(available_until: Date.current - 1.day)
  end
  
  def extend_availability(new_end_date)
    if new_end_date > available_until
      update(available_until: new_end_date)
      { success: true, message: "Availability extended" }
    else
      { success: false, message: "New date must be after current end date" }
    end
  end
  
  def delete_listing
    destroy
  end
  
  def duplicate_listing
    attributes_to_copy = attributes.except('id', 'created_at', 'updated_at')
    new_listing = self.class.new(attributes_to_copy)
    new_listing.title = "#{title} (Copy)"
    new_listing
  end
  
  private

  def self.normalize_filter_date(value)
    case value
    when Date
      value
    when String
      Date.strptime(value, "%m/%d/%Y")
    end
  rescue Date::Error
    nil
  end
  
  def available_until_after_available_from
    return unless available_from && available_until
    
    if available_until <= available_from
      errors.add(:available_until, "must be after the available from date")
    end
  end
  
  def available_from_not_in_past
    return unless available_from
    
    if available_from < Date.current
      errors.add(:available_from, "cannot be in the past")
    end
  end
end
