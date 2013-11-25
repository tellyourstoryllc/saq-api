class AddFileFieldsToMessageAttachments < ActiveRecord::Migration
  def change
    add_column :message_attachments, :media_type, :string, null: false
    add_column :message_attachments, :content_type, :string, null: false
    add_column :message_attachments, :file_size, :integer, null: false
  end
end
