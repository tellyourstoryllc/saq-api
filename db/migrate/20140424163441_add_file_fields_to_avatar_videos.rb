class AddFileFieldsToAvatarVideos < ActiveRecord::Migration
  def change
    add_column :avatar_videos, :media_type, :string, null: false
    add_column :avatar_videos, :content_type, :string, null: false
    add_column :avatar_videos, :file_size, :integer, null: false
    add_column :avatar_videos, :preview_width, :integer
    add_column :avatar_videos, :preview_height, :integer
  end
end
