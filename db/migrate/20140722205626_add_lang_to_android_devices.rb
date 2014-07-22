class AddLangToAndroidDevices < ActiveRecord::Migration
  def change
    add_column :android_devices, :lang, :string
  end
end
