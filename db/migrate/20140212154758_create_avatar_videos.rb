class CreateAvatarVideos < ActiveRecord::Migration
  def change
    create_table :avatar_videos do |t|
      t.column :user_id, 'CHAR(8)', null: false
      t.string :video, null: false # For carrierwave
      t.string :uuid, null: false
      t.timestamps

      t.index :user_id
    end
  end
end
