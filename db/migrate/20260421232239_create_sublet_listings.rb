class CreateSubletListings < ActiveRecord::Migration[8.1]
  def change
    create_table :sublet_listings do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :price
      t.text :address
      t.integer :bedrooms
      t.integer :bathrooms
      t.boolean :furnished
      t.boolean :pets_allowed
      t.boolean :utilities_included
      t.date :available_from
      t.date :available_until

      t.timestamps
    end
  end
end
