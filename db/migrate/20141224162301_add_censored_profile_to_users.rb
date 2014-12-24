class AddCensoredProfileToUsers < ActiveRecord::Migration
  def change
    add_column :users, :censored_profile, :boolean, null: false, default: false
  end
end
