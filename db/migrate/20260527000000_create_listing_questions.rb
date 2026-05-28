class CreateListingQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :listing_questions do |t|
      t.references :sublet_listing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.text :answer
      t.datetime :answered_at

      t.timestamps
    end
  end
end
