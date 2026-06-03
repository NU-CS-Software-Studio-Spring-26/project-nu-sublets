class AddContactPrivacyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :show_email_to_students, :boolean, null: false, default: false
    add_column :users, :show_phone_to_students, :boolean, null: false, default: false
  end
end
