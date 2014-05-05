class AddRegisteredAtToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :registered_at, :datetime
  end
end
