class MakeJoinCodeUniqueOnGroups < ActiveRecord::Migration
  def up
    remove_index :groups, :join_code
    add_index :groups, :join_code, unique: true
  end

  def down
    remove_index :groups, :join_code
    add_index :groups, :join_code
  end
end
