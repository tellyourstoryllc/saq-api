class RenameInvitesCanLogin < ActiveRecord::Migration
  def up
    rename_column :invites, :can_login, :can_log_in
  end

  def down
    rename_column :invites, :can_log_in, :can_login
  end
end
