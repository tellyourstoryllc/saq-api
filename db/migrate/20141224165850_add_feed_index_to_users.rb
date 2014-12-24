class AddFeedIndexToUsers < ActiveRecord::Migration
  def up
    remove_index :users, :last_public_story_created_at
    add_index :users, [:last_public_story_created_at, :deactivated, :uninstalled, :censored_profile, :gender, :latitude, :longitude], name: :for_feed
  end

  def down
    remove_index :users, name: :for_feed
    add_index :users, :last_public_story_created_at
  end
end
