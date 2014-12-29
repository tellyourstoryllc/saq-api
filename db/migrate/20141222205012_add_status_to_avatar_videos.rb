class AddStatusToAvatarVideos < ActiveRecord::Migration
  def change
    add_column :avatar_videos, :status, "ENUM('pending','review','normal','censored')"
  end
end
