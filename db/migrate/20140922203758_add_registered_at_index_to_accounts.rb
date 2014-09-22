class AddRegisteredAtIndexToAccounts < ActiveRecord::Migration
  def change
    add_index :accounts, :registered_at
  end
end
