class CreateRobotItems < ActiveRecord::Migration
  def change
    create_table :robot_items do |t|
      t.string :name, :trigger, null: false
      t.integer :rank
      t.integer :parent_id
      t.string :text, :attachment_url
      t.timestamps
    end
  end
end
