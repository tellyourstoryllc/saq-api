class ChangeIosDevicesPushToken < ActiveRecord::Migration
  def up
    change_column :ios_devices, :push_token, 'CHAR(64)'
  end

  def down
    change_column :ios_devices, :push_token, 'BINARY(32)'
  end
end
