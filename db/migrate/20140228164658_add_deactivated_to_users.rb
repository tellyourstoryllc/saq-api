class AddDeactivatedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :deactivated, :boolean, null: false, default: false
  end
end
