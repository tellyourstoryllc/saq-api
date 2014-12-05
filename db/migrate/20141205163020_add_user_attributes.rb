class AddUserAttributes < ActiveRecord::Migration
  def change
    change_table :users do |t|
      t.column :gender, "ENUM('male', 'female')"
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :location_name
      t.column :friend_code, 'CHAR(6)', null: false
    end
  end
end
