class ChangeGroupIdsToStrings < ActiveRecord::Migration
  def up
    change_column :group_wallpaper_images, :group_id, 'CHAR(8)', null: false
    change_column :message_images, :group_id, 'CHAR(8)'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
