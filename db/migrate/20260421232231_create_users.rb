class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :first_name
      t.string :last_name
      t.boolean :active
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
