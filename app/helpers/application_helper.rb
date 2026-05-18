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
    if listing_or_index.respond_to?(:photos) && listing_or_index.photos.attached?
      return url_for(listing_or_index.photos[offset % listing_or_index.photos.size])
    end

    asset_path(APARTMENT_IMAGE_ASSETS[apartment_image_index(listing_or_index, offset)])
  end

  def apartment_gallery_image_paths(listing = nil)
    return listing.photos.map { |photo| url_for(photo) } if listing.respond_to?(:photos) && listing.photos.attached?

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
      safe_join([tiny_icon_markup, content_tag(:span, label, class: "nav-item-text", style: "white-space:nowrap;")])
    end
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
