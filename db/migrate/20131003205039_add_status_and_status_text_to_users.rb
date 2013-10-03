class AddStatusAndStatusTextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :status, "ENUM('available', 'away', 'do_not_disturb', 'idle')",
      null: false, default: 'available', after: :password_digest
    add_column :users, :status_text, :string, after: :status
  end
end
