class AddFriendCodeIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :friend_code, unique: true
  end
end
