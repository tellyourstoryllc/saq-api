class AddOneToOneIdToMessageImages < ActiveRecord::Migration
  def up
    change_column :message_images, :group_id, :integer, null: true
    add_column :message_images, :one_to_one_id, :string, after: :group_id
    add_index :message_images, :one_to_one_id
  end

  def down
    remove_column :message_images, :one_to_one_id
    change_column :message_images, :group_id, :integer, null: false
  end
end
