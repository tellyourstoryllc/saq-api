class ChangeRobotItemsText < ActiveRecord::Migration
  def up
    change_column :robot_items, :text, :text, null: false
  end

  def down
    change_column :robot_items, :text, :string, null: false
  end
end
