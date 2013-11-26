class AddFacebookIdToAccounts < ActiveRecord::Migration
  def up
    add_column :accounts, :facebook_id, :string
    add_index :accounts, :facebook_id, unique: true
    change_column :accounts, :password_digest, :string, null: true
  end

  def down
    change_column :accounts, :password_digest, :string, null: false
    remove_column :accounts, :facebook_id, :string
  end
end
