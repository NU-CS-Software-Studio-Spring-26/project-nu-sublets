class HardenSubletListingConstraints < ActiveRecord::Migration[8.1]
  def up
    SubletListing.where(furnished: nil).update_all(furnished: false)
    SubletListing.where(pets_allowed: nil).update_all(pets_allowed: false)
    SubletListing.where(utilities_included: nil).update_all(utilities_included: false)

    change_column_null :sublet_listings, :title, false
    change_column_null :sublet_listings, :description, false
    change_column_null :sublet_listings, :price, false
    change_column_null :sublet_listings, :address, false
    change_column_null :sublet_listings, :bedrooms, false
    change_column_null :sublet_listings, :bathrooms, false
    change_column_null :sublet_listings, :available_from, false
    change_column_null :sublet_listings, :available_until, false
    change_column_null :sublet_listings, :furnished, false
    change_column_null :sublet_listings, :pets_allowed, false
    change_column_null :sublet_listings, :utilities_included, false

    change_column_default :sublet_listings, :furnished, from: nil, to: false
    change_column_default :sublet_listings, :pets_allowed, from: nil, to: false
    change_column_default :sublet_listings, :utilities_included, from: nil, to: false

    add_check_constraint :sublet_listings, "price > 0 AND price <= 20000", name: "sublet_listings_price_range"
    add_check_constraint :sublet_listings, "bedrooms >= 0 AND bedrooms <= 20", name: "sublet_listings_bedrooms_range"
    add_check_constraint :sublet_listings, "bathrooms >= 0 AND bathrooms <= 20", name: "sublet_listings_bathrooms_range"
    add_check_constraint :sublet_listings, "available_until > available_from", name: "sublet_listings_available_until_after_from"
  end

  def down
    remove_check_constraint :sublet_listings, name: "sublet_listings_available_until_after_from"
    remove_check_constraint :sublet_listings, name: "sublet_listings_bathrooms_range"
    remove_check_constraint :sublet_listings, name: "sublet_listings_bedrooms_range"
    remove_check_constraint :sublet_listings, name: "sublet_listings_price_range"

    change_column_default :sublet_listings, :utilities_included, from: false, to: nil
    change_column_default :sublet_listings, :pets_allowed, from: false, to: nil
    change_column_default :sublet_listings, :furnished, from: false, to: nil

    change_column_null :sublet_listings, :utilities_included, true
    change_column_null :sublet_listings, :pets_allowed, true
    change_column_null :sublet_listings, :furnished, true
    change_column_null :sublet_listings, :available_until, true
    change_column_null :sublet_listings, :available_from, true
    change_column_null :sublet_listings, :bathrooms, true
    change_column_null :sublet_listings, :bedrooms, true
    change_column_null :sublet_listings, :address, true
    change_column_null :sublet_listings, :price, true
    change_column_null :sublet_listings, :description, true
    change_column_null :sublet_listings, :title, true
  end
end
