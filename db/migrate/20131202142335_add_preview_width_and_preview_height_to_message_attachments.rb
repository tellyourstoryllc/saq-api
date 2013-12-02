class AddPreviewWidthAndPreviewHeightToMessageAttachments < ActiveRecord::Migration
  def change
    add_column :message_attachments, :preview_width, :integer
    add_column :message_attachments, :preview_height, :integer
  end
end
