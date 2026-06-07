class AddGeocodingToSubletListings < ActiveRecord::Migration[8.1]
  def change
    add_column :sublet_listings, :latitude, :decimal, precision: 10, scale: 6
    add_column :sublet_listings, :longitude, :decimal, precision: 10, scale: 6
    add_column :sublet_listings, :geocoded_at, :datetime
    add_column :sublet_listings, :geocoding_status, :string
    add_index :sublet_listings, [ :latitude, :longitude ]
  end
end
