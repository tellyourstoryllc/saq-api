class CreateAvatarImages < ActiveRecord::Migration
  def change
    create_table :avatar_images do |t|
      t.integer :user_id, null: false
      t.string :image, null: false # For carrierwave
      t.string :uuid, null: false
      t.timestamps

      t.index :user_id
    end
  end
end
