class AddLangToIosDevices < ActiveRecord::Migration
  def change
    add_column :ios_devices, :lang, :string
  end
end
