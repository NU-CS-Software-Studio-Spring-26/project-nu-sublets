class CreateListingReports < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_reports do |t|
      t.references :sublet_listing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :description, null: false
      t.string :status, null: false, default: "open"

      t.timestamps
    end

    add_index :listing_reports, :status
  end
end
