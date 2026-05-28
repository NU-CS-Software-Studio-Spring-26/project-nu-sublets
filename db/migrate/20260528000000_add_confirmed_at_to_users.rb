class AddConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :confirmed_at, :datetime
    User.reset_column_information
    User.where(confirmed_at: nil).update_all(confirmed_at: Time.current)
  end

  def down
    remove_column :users, :confirmed_at
  end
end
