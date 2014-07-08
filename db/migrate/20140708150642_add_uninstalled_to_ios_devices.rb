class AddUninstalledToIosDevices < ActiveRecord::Migration
  def change
    add_column :ios_devices, :uninstalled, :boolean, default: false
  end
end
