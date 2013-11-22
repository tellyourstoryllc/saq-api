class ChangeMessageImagesToMessageAttachments < ActiveRecord::Migration
  def up
    rename_table :message_images, :message_attachments
    rename_column :message_attachments, :image, :attachment
  end

  def down
    rename_table :message_attachments, :message_images
    rename_column :message_images, :attachment, :image
  end
end
