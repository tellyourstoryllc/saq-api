class UseCoveringIndexOnLatestAppReview < ActiveRecord::Migration
  def up
    remove_index :app_reviews, :user_id
    add_index :app_reviews, [:user_id, :rating]
  end

  def down
    remove_index :app_reviews, [:user_id, :rating]
    add_index :app_reviews, :user_id
  end
end
