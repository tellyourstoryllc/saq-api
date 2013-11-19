class AddActiveToGroupWallpaperImages < ActiveRecord::Migration
  def change
    add_column :group_wallpaper_images, :active, :boolean, null: false, default: true
  end
end
