class AddVerifiedToPhones < ActiveRecord::Migration
  def change
    add_column :phones, :verified, :boolean, null: false, default: false, after: 'number'
    add_index :phones, :verified
  end
end
