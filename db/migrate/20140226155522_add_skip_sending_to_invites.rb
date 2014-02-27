class AddSkipSendingToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :skip_sending, :boolean, null: false, default: false
  end
end
