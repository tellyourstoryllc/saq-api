class FixAppReviews < ActiveRecord::Migration
  def up
    change_column :app_reviews, :user_id, 'CHAR(8)', null: false
    add_column :app_reviews, :device_type, :string, after: :user_id
  end

  def down
    remove_column :app_reviews, :device_type
    change_column :app_reviews, :user_id, :integer, null: false
  end
end
