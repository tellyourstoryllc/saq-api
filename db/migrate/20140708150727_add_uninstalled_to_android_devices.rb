class AddUninstalledToAndroidDevices < ActiveRecord::Migration
  def change
    add_column :android_devices, :uninstalled, :boolean, default: false
  end
end
