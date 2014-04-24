class AddPublicAvatarVideoToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_avatar_video, :boolean, null: false, default: false
  end
end
