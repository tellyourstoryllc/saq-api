class ChangeUserIdsToStrings < ActiveRecord::Migration
  def up
    change_column :accounts, :user_id, 'CHAR(8)', null: false
    change_column :avatar_images, :user_id, 'CHAR(8)', null: false
    change_column :groups, :creator_id, 'CHAR(8)', null: false
    change_column :group_wallpaper_images, :creator_id, 'CHAR(8)', null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
