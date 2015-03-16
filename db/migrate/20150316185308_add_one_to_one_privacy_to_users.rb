class AddOneToOnePrivacyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :one_to_one_privacy, "ENUM('nobody', 'unblurred_public_story', 'avatar_image', 'anybody')", null: false, default: 'nobody'
  end
end
