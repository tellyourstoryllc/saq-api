class CreateMessageAttachmentOverlays < ActiveRecord::Migration
  def change
    create_table :message_attachment_overlays do |t|
      t.string :one_to_one_id
      t.column :message_id, 'CHAR(10)', null: false
      t.string :overlay, :uuid, null: false
      t.integer :file_size, null: false
      t.timestamps

      t.index :one_to_one_id
      t.index :message_id
    end
  end
end
