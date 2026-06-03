class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :initiator, null: false, foreign_key: { to_table: :users }
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :sublet_listing, foreign_key: true
      t.string :conversation_key, null: false

      t.timestamps
    end

    add_index :conversations, :conversation_key, unique: true
    add_index :conversations, [ :initiator_id, :recipient_id ]
    add_index :conversations, [ :recipient_id, :initiator_id ]
  end
end
