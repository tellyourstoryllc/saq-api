class CreateMessageImages < ActiveRecord::Migration
  def change
    create_table :message_images do |t|
      t.integer :group_id, :message_id, null: false
      t.string :image, null: false # For carrierwave
      t.timestamps

      t.index :group_id
      t.index :message_id
    end
  end
end
