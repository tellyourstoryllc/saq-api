class AddDurationToMessageAttachments < ActiveRecord::Migration
  def change
    add_column :message_attachments, :duration, :integer
  end
end
