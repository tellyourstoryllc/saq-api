class CreateOneToOneWallpaperImages < ActiveRecord::Migration
  def change
    create_table :one_to_one_wallpaper_images do |t|
      t.integer :account_id, null: false
      t.string :image, null: false # For carrierwave
      t.string :uuid, null: false
      t.timestamps

      t.index :account_id
    end
  end
end
