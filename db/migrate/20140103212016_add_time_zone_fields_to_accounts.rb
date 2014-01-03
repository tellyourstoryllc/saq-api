class AddTimeZoneFieldsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :time_zone, :string, null: false
    add_column :accounts, :time_zone_offset, 'MEDIUMINT(9)', null: false
  end
end
