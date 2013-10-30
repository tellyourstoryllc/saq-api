class RemoveIdleFromUsersStatus < ActiveRecord::Migration
  def up
    change_column :users, :status, "ENUM('available','away','do_not_disturb')", default: 'available'
  end

  def down
    change_column :users, :status, "ENUM('available','away','do_not_disturb','idle')", default: 'available'
  end
end
