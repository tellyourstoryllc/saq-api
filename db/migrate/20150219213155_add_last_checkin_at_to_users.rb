class AddLastCheckinAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_checkin_at, :datetime, null: false, default: '2000-01-01'
    add_index :users, :last_checkin_at
  end
end
