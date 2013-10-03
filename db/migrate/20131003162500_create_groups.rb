class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.integer :creator_id, null: false
      t.string :name, null: false
      t.column :join_code, 'CHAR(8)', null: false
      t.string :topic
      t.timestamps

      t.index :creator_id
      t.index :join_code
    end
  end
end
