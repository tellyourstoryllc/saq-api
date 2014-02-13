class AddInvitedPhoneToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :invited_phone, :string, limit: 50, after: 'invited_email'
  end
end
