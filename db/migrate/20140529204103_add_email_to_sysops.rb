class AddEmailToSysops < ActiveRecord::Migration
  def change
    add_column :sysops, :email, :string
    add_index :sysops, :email, unique: true
  end
end
