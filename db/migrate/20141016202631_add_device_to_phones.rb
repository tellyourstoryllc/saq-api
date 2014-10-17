class AddDeviceToPhones < ActiveRecord::Migration
  def change
    add_column :phones, :device_type, :string, after: :id
    add_column :phones, :device_id, :integer, after: :device_type
    add_index :phones, [:device_type, :device_id]
  end
end
