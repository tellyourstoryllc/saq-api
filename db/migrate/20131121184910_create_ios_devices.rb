class CreateIosDevices < ActiveRecord::Migration
  def change
    create_table :ios_devices do |t|
      t.column :user_id, 'CHAR(8)'
      t.column :device_id, 'CHAR(32)', null: false
      t.column :client_version, 'VARCHAR(5)', null: false
      t.column :os_version, 'VARCHAR(5)', null: false
      t.column :push_token, 'BINARY(32)', null: false
      t.timestamps

      t.index :user_id
      t.index :device_id, unique: true
    end
  end
end
