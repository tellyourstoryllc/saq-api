class CreateVideoThumbnails < ActiveRecord::Migration
  def change
    create_table :video_thumbnails do |t|
      t.integer :video_id, null: false
      t.column :status, "ENUM('pending','review','normal','censored')"
      t.string :image, null: false # For carrierwave
      t.integer :offset

      t.timestamps

      t.index :video_id
    end
  end
end
