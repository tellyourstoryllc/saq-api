class CreateGroupWallpaperImages < ActiveRecord::Migration
  def change
    create_table :group_wallpaper_images do |t|
      t.integer :group_id, null: false
      t.integer :creator_id, null: false
      t.string :image, null: false # For carrierwave
      t.string :uuid, null: false
      t.timestamps

      t.index :group_id
    end
  end
end
