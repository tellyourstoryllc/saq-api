class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.integer :account_id, null: false
      t.column :user_id, 'CHAR(8)', null: false
      t.string :email, null: false
      t.timestamps

      t.index :account_id
      t.index :user_id
      t.index :email, unique: true
    end
  end
end
