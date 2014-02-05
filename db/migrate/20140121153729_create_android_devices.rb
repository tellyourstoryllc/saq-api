class CreateAndroidDevices < ActiveRecord::Migration
  def change
    create_table :android_devices do |t|
      t.column :user_id, 'CHAR(8)'
      t.string :device_id, null: false
      t.column :client_version, 'VARCHAR(5)', null: false
      t.column :os_version, 'VARCHAR(5)', null: false
      t.string :registration_id
      t.timestamps

      t.index :user_id
      t.index :device_id, unique: true
    end
  end
end
