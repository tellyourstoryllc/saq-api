class AddPublicAvatarImageToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_avatar_image, :boolean, null: false, default: false
  end
end
