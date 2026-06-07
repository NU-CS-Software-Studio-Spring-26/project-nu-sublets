class AddConversationReadTimestamps < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :last_read_at_initiator, :datetime
    add_column :conversations, :last_read_at_recipient, :datetime
  end
end
