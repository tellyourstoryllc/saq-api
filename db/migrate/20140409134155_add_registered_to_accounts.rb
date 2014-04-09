class AddRegisteredToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :registered, :boolean, null: false, default: false
  end
end
