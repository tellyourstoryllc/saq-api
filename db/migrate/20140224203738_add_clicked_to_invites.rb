class AddClickedToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :clicked, :boolean, null: false, default: false
  end
end
