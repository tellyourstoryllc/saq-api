class MakeGroupsPrimaryKeyString < ActiveRecord::Migration
  def up
    change_column :groups, :id, 'CHAR(8)', null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
