class AddLastPublicStoryUnblurredToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_public_story_unblurred, :boolean
  end
end
