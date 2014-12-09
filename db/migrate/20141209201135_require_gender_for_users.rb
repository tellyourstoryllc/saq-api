class RequireGenderForUsers < ActiveRecord::Migration
  def up
    change_column :users, :gender, "ENUM('male', 'female')", null: false
  end

  def down
    change_column :users, :gender, "ENUM('male', 'female')", null: true
  end
end
