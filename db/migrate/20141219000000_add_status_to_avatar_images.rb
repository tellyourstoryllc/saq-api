class AddStatusToAvatarImages < ActiveRecord::Migration
  def change
    add_column :avatar_images, :status, "ENUM('pending','review','normal','censored')"
  end
end
