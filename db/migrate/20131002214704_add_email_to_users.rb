class AddEmailToUsers < ActiveRecord::Migration
  def up
    add_column :users, :email, :string, after: :name
    change_column :users, :password_digest, :string, null: true
  end

  def down
    change_column :users, :password_digest, :string, null: false
    remove_column :users, :email
  end
end
