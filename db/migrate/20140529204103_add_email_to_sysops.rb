class AddEmailToSysops < ActiveRecord::Migration
  def change
    add_column :sysops, :email, :string
  end
end
