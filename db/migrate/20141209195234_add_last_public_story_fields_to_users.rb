class AddLastPublicStoryFieldsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_public_story_id, 'CHAR(10)'
    add_column :users, :last_public_story_created_at, :datetime
    add_index :users, :last_public_story_created_at
  end
end
