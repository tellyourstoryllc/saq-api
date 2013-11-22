class MakeUsersPrimaryKeyString < ActiveRecord::Migration
  def up
    change_column :users, :id, 'CHAR(8)', null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
