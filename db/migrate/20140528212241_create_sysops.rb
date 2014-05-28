class CreateSysops < ActiveRecord::Migration
  def change
    create_table :sysops do |t|
      t.string :name, null: false
      t.string :password_digest
      t.string :token
      t.timestamps

      t.index :name, unique: true
      t.index :token, unique: true
    end
  end
end
