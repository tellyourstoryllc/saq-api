class AddActiveToOneToOneWallpaperImages < ActiveRecord::Migration
  def change
    add_column :one_to_one_wallpaper_images, :active, :boolean, null: false, default: true
  end
end
