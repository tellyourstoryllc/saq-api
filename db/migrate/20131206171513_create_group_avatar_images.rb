class CreateGroupAvatarImages < ActiveRecord::Migration
  def change
    create_table :group_avatar_images do |t|
      t.column :group_id, 'CHAR(8)', null: false
      t.column :creator_id, 'CHAR(8)', null: false
      t.string :image, null: false # For carrierwave
      t.string :uuid, null: false
      t.boolean :active, null: false, default: true
      t.timestamps

      t.index :group_id
    end
  end
end
