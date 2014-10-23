class IncreaseClientVersionSize < ActiveRecord::Migration
  def up
    change_column :ios_devices, :client_version, :string, limit: 255, null: false
    change_column :android_devices, :client_version, :string, limit: 255, null: false
  end

  def down
    change_column :android_devices, :client_version, :string, limit: 5, null: false
    change_column :ios_devices, :client_version, :string, limit: 5, null: false
  end
end
