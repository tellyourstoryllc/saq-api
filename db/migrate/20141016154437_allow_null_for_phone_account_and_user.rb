class AllowNullForPhoneAccountAndUser < ActiveRecord::Migration
  def up
    change_column :phones, :account_id, :integer, null: true
    change_column :phones, :user_id, 'CHAR(8)', null: true
  end

  def down
    change_column :phones, :user_id, 'CHAR(8)', null: false
    change_column :phones, :account_id, :integer, null: false
  end
end
