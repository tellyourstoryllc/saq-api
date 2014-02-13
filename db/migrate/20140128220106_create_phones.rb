class CreatePhones < ActiveRecord::Migration
  def change
    create_table :phones do |t|
      t.integer :account_id, null: false
      t.column :user_id, 'CHAR(8)', null: false
      t.string :number, limit: 50, null: false
      t.boolean :unsubscribed, null: false, default: false
      t.timestamps

      t.index :account_id
      t.index :user_id
      t.index :number, unique: true
    end
  end
end
