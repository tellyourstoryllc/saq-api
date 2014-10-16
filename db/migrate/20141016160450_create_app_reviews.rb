class CreateAppReviews < ActiveRecord::Migration
  def change
    create_table :app_reviews do |t|
      t.integer :user_id, null: false
      t.integer :device_id
      t.integer :rating, null: false
      t.text :feedback
      t.boolean :will_write_review
      t.timestamps

      t.index :user_id
      t.index :rating
    end
  end
end
