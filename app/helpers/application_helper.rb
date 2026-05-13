require "digest"

module ApplicationHelper
  APARTMENT_IMAGE_ASSETS = [
    "apartment-bedroom.png",
    "apartment-living-room.png",
    "apartment-kitchen.png",
    "apartment-exterior.png"
  ].freeze

  PLACEHOLDER_PROFILE_PHOTO_URLS = [
    "https://randomuser.me/api/portraits/women/65.jpg",
    "https://randomuser.me/api/portraits/men/73.jpg",
    "https://randomuser.me/api/portraits/women/27.jpg",
    "https://randomuser.me/api/portraits/men/15.jpg",
    "https://randomuser.me/api/portraits/women/32.jpg",
    "https://randomuser.me/api/portraits/men/12.jpg",
    "https://randomuser.me/api/portraits/women/18.jpg",
    "https://randomuser.me/api/portraits/men/8.jpg",
    "https://randomuser.me/api/portraits/women/12.jpg",
    "https://randomuser.me/api/portraits/women/28.jpg",
    "https://randomuser.me/api/portraits/men/18.jpg",
    "https://randomuser.me/api/portraits/women/24.jpg"
  ].freeze

  def listing_map_groups(listings)
    listings.group_by { |listing| normalized_listing_address(listing.address) }
            .values
            .map { |group| listing_map_group(group) }
  end

  def apartment_listing_image_path(listing_or_index = nil, offset: 0)
    asset_path(APARTMENT_IMAGE_ASSETS[apartment_image_index(listing_or_index, offset)])
  end

  def apartment_gallery_image_paths(listing = nil)
    APARTMENT_IMAGE_ASSETS.each_with_index.map do |_asset, index|
      apartment_listing_image_path(listing, offset: index)
    end
  end

  def user_initials(user)
    display_name = user&.display_name.presence || user&.email.to_s.split("@").first
    display_name.to_s.split.map { |part| part.first }.join.first(2).upcase.presence || "NU"
  end

  def user_avatar_url(user, size: 248)
    return url_for(user.profile_photo) if user.respond_to?(:profile_photo) && user.profile_photo.attached?

    if user.respond_to?(:profile_photo_url) && user.profile_photo_url.present? && !placeholder_profile_photo_url?(user.profile_photo_url)
      return user.profile_photo_url
    end

    "https://ui-avatars.com/api/?name=#{ERB::Util.url_encode(user_initials(user))}&background=F4EFF8&color=3E1B4B&size=#{size}&bold=true"
  end

  private

  def placeholder_profile_photo_url?(url)
    PLACEHOLDER_PROFILE_PHOTO_URLS.include?(url)
  end

  def apartment_image_index(listing_or_index, offset)
    # Keep demo images stable between renders without storing image records.
    base = if listing_or_index.respond_to?(:id) && listing_or_index.id.present?
             listing_or_index.id
    elsif listing_or_index.is_a?(Integer)
             listing_or_index
    else
             listing_or_index.to_s.sum
    end

    (base.to_i + offset) % APARTMENT_IMAGE_ASSETS.length
  end

  def normalized_listing_address(address)
    map_address(address).downcase.gsub(/[^a-z0-9]+/, " ").squeeze(" ").strip
  end

  def listing_map_group(listings)
    address = map_address(listings.first.address)

    {
      address: address,
      listings: listings,
      x: map_coordinate(address, 0),
      y: map_coordinate(address, 1)
    }
  end

  def map_coordinate(address, offset)
    # Deterministic pseudo-coordinates keep pins grouped until real geocoding is added.
    digest = Digest::MD5.hexdigest(normalized_listing_address(address))
    value = digest[offset * 4, 4].to_i(16)

    12 + (value % 76)
  end

  def map_address(address)
    address.to_s.split(",").first.to_s.strip
  end
end
