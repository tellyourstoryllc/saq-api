class MakeUsersGenderOptional < ActiveRecord::Migration
  def up
    change_column :users, :gender, "ENUM('male', 'female')", null: true
  end

  def down
    change_column :users, :gender, "ENUM('male', 'female')", null: false
  end
end
