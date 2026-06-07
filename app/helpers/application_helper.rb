require "digest"

module ApplicationHelper
  NAV_ITEM_ICONS = {
    browse: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M8.354 1.146a.5.5 0 0 0-.708 0l-6 6A.5.5 0 0 0 2 8h.5v6A1.5 1.5 0 0 0 4 15.5h8a1.5 1.5 0 0 0 1.5-1.5V8h.5a.5.5 0 0 0 .354-.854zM13 7.5V14a1 1 0 0 1-1 1H9.5v-3.5a1.5 1.5 0 0 0-3 0V15H4a1 1 0 0 1-1-1V7.5a.5.5 0 0 0-.146-.354L8 2.207l5.146 4.939A.5.5 0 0 0 13 7.5"/></svg>'.html_safe,
    search: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M11.742 10.344a6.5 6.5 0 1 0-1.398 1.398h-.001q.044.06.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1 1 0 0 0-.115-.1zM12 6.5a5.5 5.5 0 1 1-11 0 5.5 5.5 0 0 1 11 0"/></svg>'.html_safe,
    saved: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="m8 2.748-.717-.737C5.6.281 2.514.878 1.4 3.053c-.523 1.023-.641 2.5.314 4.385.92 1.815 2.834 3.989 6.286 6.357 3.452-2.368 5.365-4.542 6.286-6.357.955-1.886.838-3.362.314-4.385C13.486.878 10.4.28 8.717 2.01z"/></svg>'.html_safe,
    post_sublet: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M8.354 1.146a.5.5 0 0 0-.708 0l-6 6A.5.5 0 0 0 2 8h.5v6A1.5 1.5 0 0 0 4 15.5h8a1.5 1.5 0 0 0 1.5-1.5V8h.5a.5.5 0 0 0 .354-.854zM13 7.5V14a1 1 0 0 1-1 1H9v-3.5a1 1 0 0 0-2 0V15H4a1 1 0 0 1-1-1V7.5a.5.5 0 0 0-.146-.354L8 2.207l5.146 4.939A.5.5 0 0 0 13 7.5"/><path fill="currentColor" d="M8 5.5a.5.5 0 0 1 .5.5v1h1a.5.5 0 0 1 0 1h-1v1a.5.5 0 0 1-1 0V8h-1a.5.5 0 0 1 0-1h1V6a.5.5 0 0 1 .5-.5"/></svg>'.html_safe,
    about_us: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/><path fill="currentColor" d="m8.93 6.588-2.29.287-.082.38.45.083c.294.07.352.176.288.469l-.738 3.468c-.194.897.105 1.319.808 1.319.545 0 .877-.252 1.02-.598l.088-.416c.066-.305.125-.38.415-.38h.5l.082-.381-.45-.083c-.294-.07-.352-.176-.288-.469l.738-3.468c.194-.897-.105-1.319-.808-1.319-.545 0-.877.252-1.02.598zM8 5.5a1 1 0 1 0 0-2 1 1 0 0 0 0 2"/></svg>'.html_safe,
    privacy_policy: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M5.072.56C6.157.221 7.9 0 8 0s1.843.221 2.928.56c1.11.346 2.247.87 3.094 1.567.85.699 1.478 1.555 1.478 2.54 0 1.31-.53 2.91-1.39 4.43-.857 1.516-2.06 2.975-3.33 4.107C9.515 14.336 8.335 15 8 15s-1.515-.664-2.78-1.796c-1.27-1.132-2.473-2.59-3.33-4.107C1.03 7.577.5 5.976.5 4.667c0-.985.629-1.841 1.478-2.54C2.825 1.429 3.963.906 5.072.56"/><path fill="white" d="M8 4a2 2 0 0 0-2 2v1H5a1 1 0 0 0-1 1v2.5A1.5 1.5 0 0 0 5.5 12h5A1.5 1.5 0 0 0 12 10.5V8a1 1 0 0 0-1-1h-1V6a2 2 0 0 0-2-2m1 3H7V6a1 1 0 1 1 2 0z"/></svg>'.html_safe,
    disclaimer: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h6.5z"/><path fill="white" d="M8 7a.75.75 0 0 1 .75.75v2.5a.75.75 0 0 1-1.5 0v-2.5A.75.75 0 0 1 8 7m0 5a.875.875 0 1 0 0-1.75A.875.875 0 0 0 8 12"/><path fill="currentColor" d="M14 4.5h-2A1.5 1.5 0 0 1 10.5 3v-2z"/></svg>'.html_safe,
    github: '<svg class="nav-item-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M8 0C3.58 0 0 3.58 0 8a8.01 8.01 0 0 0 5.47 7.59c.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49C4 14.09 3.48 13.2 3.32 12.74c-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.5-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82a7.54 7.54 0 0 1 4 0c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8"/></svg>'.html_safe
  }.freeze

  APARTMENT_IMAGE_ASSETS = [
    "apartment-bedroom.png",
    "apartment-living-room.png",
    "apartment-kitchen.png",
    "apartment-exterior.png"
  ].freeze
  DEFAULT_LISTING_IMAGE_ASSET = "apartment-exterior.png"

  AMENITY_ICON_PATHS = {
    "Furnished" => '<path d="M4 11h16v7H4zM7 11V7a3 3 0 0 1 3-3h4a3 3 0 0 1 3 3v4M7 18v2m10-2v2" />',
    "Laundry" => '<rect x="6" y="3" width="12" height="18" rx="2" /><circle cx="12" cy="13" r="4" /><path d="M9 7h.01M13 7h2" />',
    "AC / Heat" => '<path d="M12 3v18M8 5l4 4 4-4M8 19l4-4 4 4M4 8l16 8M4 16l16-8" />',
    "WiFi" => '<path d="M5 10a11 11 0 0 1 14 0M8 13a6.5 6.5 0 0 1 8 0M11 16a2 2 0 0 1 2 0" /><circle cx="12" cy="19" r="1" />',
    "TV" => '<rect x="4" y="6" width="16" height="11" rx="2" /><path d="M9 21h6M12 17v4" />',
    "Hardwood floors" => '<path d="M4 5h16M4 12h16M4 19h16M8 5v7m8 0v7M12 12v7" />',
    "Natural light" => '<circle cx="12" cy="12" r="4" /><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4" />',
    "Storage" => '<path d="M5 8h14v13H5zM8 8V5h8v3M10 13h4" />',
    "Private bathroom" => '<path d="M5 11h14v4a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5zM8 11V6a3 3 0 0 1 5-2M4 21h16" />',
    "Shared bathroom" => '<path d="M5 11h14v4a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5zM8 11V6a3 3 0 0 1 5-2M4 21h16" />',
    "Private bath / Shared bath" => '<path d="M5 11h14v4a5 5 0 0 1-5 5H10a5 5 0 0 1-5-5zM8 11V6a3 3 0 0 1 5-2M4 21h16" />',
    "Updated kitchen" => '<path d="M5 3h14v18H5zM9 3v18M13 8h3M13 14h3" />',
    "Dishwasher" => '<rect x="6" y="3" width="12" height="18" rx="2" /><path d="M6 8h12M9 13h6M10 17h4" />',
    "Microwave" => '<rect x="3" y="6" width="18" height="12" rx="2" /><path d="M15 6v12M18 10h.01M18 14h.01M6 10h8v4H6z" />',
    "Balcony / Patio" => '<path d="M4 20h16M6 20V9h12v11M9 20v-6m3 6v-6m3 6v-6M8 9V5h8v4" />',
    "Elevator" => '<rect x="6" y="3" width="12" height="18" rx="2" /><path d="M10 8l2-2 2 2M10 16l2 2 2-2M12 6v12" />',
    "Secure entry" => '<rect x="5" y="10" width="14" height="10" rx="2" /><path d="M8 10V7a4 4 0 0 1 8 0v3M12 14v3" />',
    "Doorman" => '<path d="M7 21V5a2 2 0 0 1 2-2h8v18M7 21h12M11 12h.01" />',
    "Package room" => '<path d="M4 8l8-4 8 4-8 4zM4 8v8l8 4 8-4V8M12 12v8" />',
    "Bike storage" => '<circle cx="6" cy="17" r="3" /><circle cx="18" cy="17" r="3" /><path d="M8 17l4-8 4 8M10 13h6M12 9h3" />',
    "Gym" => '<path d="M3 12h18M5 9v6M8 8v8M16 8v8M19 9v6" />',
    "Rooftop" => '<path d="M3 12l9-7 9 7M6 10v10h12V10M10 20v-5h4v5" />',
    "Study rooms" => '<path d="M5 4h11a3 3 0 0 1 3 3v14H8a3 3 0 0 1-3-3zM5 4v14a3 3 0 0 0 3 3M9 8h6M9 12h6" />',
    "Parking" => '<rect x="5" y="3" width="14" height="18" rx="2" /><path d="M9 17V7h4a3 3 0 0 1 0 6H9" />',
    "Pet-friendly" => '<path d="M8 11c1.5-2 6.5-2 8 0 2 2.5 1 6-4 6s-6-3.5-4-6z" /><circle cx="6" cy="7" r="1.5" /><circle cx="10" cy="5" r="1.5" /><circle cx="14" cy="5" r="1.5" /><circle cx="18" cy="7" r="1.5" />',
    "Near Northwestern University" => '<path d="M3 8l9-5 9 5-9 5zM6 10v6c2 2 10 2 12 0v-6M8 21h8" />',
    "Downtown Evanston" => '<path d="M4 21V7h6v14M10 21V3h10v18M7 11h.01M7 15h.01M14 7h.01M17 7h.01M14 11h.01M17 11h.01M14 15h.01M17 15h.01" />',
    "Transit access" => '<rect x="5" y="4" width="14" height="13" rx="2" /><path d="M8 17l-2 3M16 17l2 3M8 8h8M8 13h.01M16 13h.01" />',
    "Lakefront (Lake Michigan)" => '<path d="M3 16c2-2 4-2 6 0s4 2 6 0 4-2 6 0M3 20c2-2 4-2 6 0s4 2 6 0 4-2 6 0M12 4v8M8 8l4-4 4 4" />',
    "Grocery nearby" => '<path d="M6 7h15l-2 8H8zM6 7 5 4H3M9 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2M18 20a1 1 0 1 0 0-2 1 1 0 0 0 0 2" />',
    "Restaurants" => '<path d="M7 3v8M4 3v5a3 3 0 0 0 6 0V3M7 11v10M15 3v18M15 3c3 2 4 6 1 9" />',
    "Safe area" => '<path d="M12 3l8 4v5c0 5-3.5 8-8 9-4.5-1-8-4-8-9V7zM9 12l2 2 4-4" />',
    "Utilities included" => '<path d="M13 2 5 13h7l-1 9 8-12h-7z" />',
    "Flexible lease" => '<rect x="4" y="5" width="16" height="16" rx="2" /><path d="M8 3v4M16 3v4M4 10h16M9 15h6" />',
    "Lease option" => '<path d="M6 3h9l3 3v18H6zM14 3v5h5M9 13h6M9 17h6" />',
    "Clean space" => '<path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2zM5 16l1 2 2 1-2 1-1 2-1-2-2-1 2-1z" />',
    "Stocked kitchen" => '<path d="M5 4h14v17H5zM8 8h11M9 4v17M12 12h4M12 16h4" />',
    "Work setup" => '<path d="M4 5h16v11H4zM9 21h6M12 16v5M8 9h8" />',
    "Quiet / Social" => '<path d="M4 9v6h4l5 4V5L8 9zM17 9a4 4 0 0 1 0 6M20 7a8 8 0 0 1 0 10" />'
  }.freeze

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

  EVANSTON_MAP_WATER_START_X = 77
  EVANSTON_MAP_FALLBACK_MAX_X = EVANSTON_MAP_WATER_START_X - 5
  EVANSTON_MAP_NORTH_SOUTH_STREETS = {
    "ridge" => 18,
    "oak" => 34,
    "maple" => 40,
    "sherman" => 48,
    "orrington" => 56,
    "chicago" => 64,
    "hinman" => 70,
    "judson" => 73
  }.freeze
  EVANSTON_MAP_EAST_WEST_STREETS = {
    "central" => 14,
    "noyes" => 30,
    "foster" => 38,
    "emerson" => 46,
    "clark" => 53,
    "davis" => 60,
    "garnett" => 70
  }.freeze

  def listing_map_groups(listings)
    listings.group_by { |listing| normalized_listing_address(listing.address) }
            .values
            .map { |group| listing_map_group(group) }
  end

  def google_maps_api_key
    ENV["GOOGLE_MAPS_API_KEY"].to_s
  end

  def google_maps_map_id
    ENV["GOOGLE_MAPS_MAP_ID"].presence || "DEMO_MAP_ID"
  end

  def google_maps_enabled?
    google_maps_api_key.present?
  end

  def google_map_listing_payload(listings)
    listings.select(&:geocoded?).map do |listing|
      {
        id: listing.id.to_s,
        href: sublet_listing_path(listing),
        title: listing.title.presence || listing.short_address.presence || "Sublet listing",
        price: listing.price.to_f,
        priceLabel: compact_price_label(listing.price),
        rentLabel: "#{number_to_currency(listing.price, precision: 0)}/month",
        address: listing.address,
        thumbnailUrl: apartment_listing_image_path(listing),
        thumbnailAlt: listing.title.presence || "Sublet listing",
        bedrooms: listing.bedrooms,
        bathrooms: listing.bathrooms,
        availableFrom: listing.available_from&.strftime("%b %-d"),
        availableUntil: listing.available_until&.strftime("%b %-d"),
        latitude: listing.latitude.to_f,
        longitude: listing.longitude.to_f
      }
    end
  end

  def apartment_listing_image_path(listing_or_index = nil, offset: 0)
    if listing_or_index.respond_to?(:photos) && listing_or_index.photos.attached?
      return url_for(listing_or_index.photos[offset % listing_or_index.photos.size])
    end

    if listing_or_index.respond_to?(:photos)
      return asset_path(DEFAULT_LISTING_IMAGE_ASSET)
    end

    asset_path(APARTMENT_IMAGE_ASSETS[apartment_image_index(listing_or_index, offset)])
  end

  def apartment_gallery_image_paths(listing = nil)
    return listing.photos.map { |photo| url_for(photo) } if listing.respond_to?(:photos) && listing.photos.attached?

    return Array.new(4) { asset_path(DEFAULT_LISTING_IMAGE_ASSET) } if listing.respond_to?(:photos)

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

  def nav_item_label_with_icon(icon_name, label)
    icon_markup = NAV_ITEM_ICONS[icon_name.to_sym] || NAV_ITEM_ICONS[:browse]
    tiny_icon_markup = icon_markup.sub(
      "<svg ",
      '<svg width="16" height="16" style="width:1em;height:1em;min-width:1em;min-height:1em;flex:0 0 1em;display:inline-block;vertical-align:-0.1em;" '
    ).html_safe

    content_tag(:span, class: "nav-item-with-icon", style: "display:inline-flex;align-items:center;gap:0.35em;white-space:nowrap;") do
      safe_join([ tiny_icon_markup, content_tag(:span, label, class: "nav-item-text", style: "white-space:nowrap;") ])
    end
  end

  def amenity_icon(amenity, css_class: "amenity-icon")
    paths = AMENITY_ICON_PATHS.fetch(amenity, AMENITY_ICON_PATHS.fetch("Furnished"))

    %(<svg class="#{css_class}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" aria-hidden="true" focusable="false">#{paths}</svg>).html_safe
  end

  def listing_compare_data_attributes(listing)
    tag.attributes(data: { compare_listing: listing_compare_payload(listing).to_json })
  end

  private

  def compact_price_label(price)
    amount = price.to_i
    return number_to_currency(amount, precision: 0) if amount < 1_000

    "$#{(amount / 1_000.0).round(1).to_s.sub(/\.0\z/, '')}k"
  end

  def listing_compare_payload(listing)
    amenities = listing.displayed_amenities
    persisted_listing = listing.persisted?

    {
      id: persisted_listing ? listing.id.to_s : fallback_compare_listing_id(listing),
      href: persisted_listing ? sublet_listing_path(listing) : listing_path,
      title: listing.title.presence || listing.short_address.presence || "Sublet listing",
      titleOrAddress: listing.title.presence || listing.address.presence || "Sublet listing",
      address: listing.address.presence || "Not listed",
      thumbnailUrl: apartment_listing_image_path(listing),
      thumbnailAlt: listing.title.presence || "Sublet listing",
      rent: number_to_currency(listing.price, precision: 0),
      rentLabel: "#{number_to_currency(listing.price, precision: 0)}/month",
      location: listing.address.presence || "Not listed",
      distanceToCampus: "N/A",
      availableFrom: listing.available_from&.strftime("%b %-d, %Y") || "N/A",
      availableUntil: listing.available_until&.strftime("%b %-d, %Y") || "N/A",
      roomType: listing_room_type(listing),
      furnished: listing.furnished? ? "Furnished" : "Unfurnished",
      utilitiesIncluded: listing.utilities_included? ? "Included" : "Not included",
      amenities: amenities.presence || [ "Not listed" ],
      petFriendly: listing.pets_allowed? ? "Yes" : "No",
      parking: amenities.include?("Parking") ? "Listed" : "Not listed",
      laundry: amenities.any? { |amenity| amenity.match?(/laundry/i) } ? "Listed" : "Not listed"
    }
  end

  def listing_room_type(listing)
    return "Studio" if listing.bedrooms.to_i.zero?

    pluralize(listing.bedrooms, "bedroom")
  end

  def fallback_compare_listing_id(listing)
    digest_input = [
      listing.title,
      listing.address,
      listing.price,
      listing.available_from,
      listing.available_until
    ].join("|")

    "preview-#{Digest::MD5.hexdigest(digest_input)[0, 12]}"
  end

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
    x, y = map_coordinates(address)

    {
      address: address,
      listings: listings,
      x: x,
      y: y
    }
  end

  def map_coordinates(address)
    street_number, street_name = map_address_parts(address)

    if street_number && EVANSTON_MAP_NORTH_SOUTH_STREETS.key?(street_name)
      return [
        EVANSTON_MAP_NORTH_SOUTH_STREETS.fetch(street_name),
        interpolate_map_coordinate(street_number, from: 600..2300, to: 84..12)
      ]
    end

    if street_number && EVANSTON_MAP_EAST_WEST_STREETS.key?(street_name)
      return [
        interpolate_map_coordinate(street_number, from: 600..1700, to: 73..18),
        EVANSTON_MAP_EAST_WEST_STREETS.fetch(street_name)
      ]
    end

    fallback_map_coordinates(address)
  end

  def map_address_parts(address)
    match = map_address(address).downcase.match(/\A\s*(\d+)\s+([a-z]+)/)
    return [ nil, nil ] unless match

    [ match[1].to_i, match[2] ]
  end

  def interpolate_map_coordinate(value, from:, to:)
    percent = (value - from.begin).to_f / (from.end - from.begin)
    projected = to.begin + (percent * (to.end - to.begin))

    projected.clamp([ to.begin, to.end ].min, [ to.begin, to.end ].max).round(1)
  end

  def fallback_map_coordinates(address)
    # Keep unknown addresses deterministic, but constrain pins to the land portion of the illustrated map.
    digest = Digest::MD5.hexdigest(normalized_listing_address(address))
    x_value = digest[0, 4].to_i(16)
    y_value = digest[4, 4].to_i(16)

    [
      12 + (x_value % (EVANSTON_MAP_FALLBACK_MAX_X - 11)),
      12 + (y_value % 76)
    ]
  end

  def map_address(address)
    address.to_s.split(",").first.to_s.strip
  end
end
