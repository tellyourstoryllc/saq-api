class AddUninstalledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uninstalled, :boolean, null: false, default: false
  end
end
