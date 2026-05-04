class AddAmenitiesAndPreferencesToSubletListings < ActiveRecord::Migration[8.1]
  def change
    add_column :sublet_listings, :amenities, :text
    add_column :sublet_listings, :preferences, :text
  end
end
