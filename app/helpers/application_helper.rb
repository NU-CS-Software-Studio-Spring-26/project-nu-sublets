require "digest"

module ApplicationHelper
  def listing_map_groups(listings)
    listings.group_by { |listing| normalized_listing_address(listing.address) }
            .values
            .map { |group| listing_map_group(group) }
  end

  private

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
    digest = Digest::MD5.hexdigest(normalized_listing_address(address))
    value = digest[offset * 4, 4].to_i(16)

    12 + (value % 76)
  end

  def map_address(address)
    address.to_s.split(",").first.to_s.strip
  end
end
