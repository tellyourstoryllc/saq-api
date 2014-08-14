class AddShaToMessageAttachments < ActiveRecord::Migration
  def change
    add_column :message_attachments, :sha, :string, null: false
    add_index :message_attachments, :sha
  end
end
