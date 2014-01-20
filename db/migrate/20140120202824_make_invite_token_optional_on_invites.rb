class MakeInviteTokenOptionalOnInvites < ActiveRecord::Migration
  def up
    change_column :invites, :invite_token, :string, null: true
  end

  def down
    change_column :invites, :invite_token, :string, null: false
  end
end
