class AddLocationFieldsForLastPublicStory < ActiveRecord::Migration
  def change
    add_column :users, :last_public_story_latitude, :decimal, precision: 10, scale: 7
    add_column :users, :last_public_story_longitude, :decimal, precision: 10, scale: 7
    add_index :users, [:last_public_story_latitude, :last_public_story_longitude], name: 'index_on_last_public_story_location'
  end
end
