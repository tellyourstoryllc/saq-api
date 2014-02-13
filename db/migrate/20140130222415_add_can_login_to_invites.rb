class AddCanLoginToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :can_login, :boolean, null: false, after: 'new_user'
  end
end
