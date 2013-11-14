class AddUsernameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :username, :string, null: false, after: :name

    User.find_each do |user|
      user.send(:set_username)
      user.save!
    end

    add_index :users, :username, unique: true
  end
end
