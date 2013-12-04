class MakePushTokenOptional < ActiveRecord::Migration
  def up
    change_column :ios_devices, :push_token, 'BINARY(32)', null: true
  end

  def down
    change_column :ios_devices, :push_token, 'BINARY(32)', null: false
  end
end
