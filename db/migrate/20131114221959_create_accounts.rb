class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id, null: false
      t.string :email, :password_digest, null: false
      t.timestamps

      t.index :user_id, unique: true
    end

    User.find_each do |user|
      Account.connection.execute("INSERT INTO accounts (user_id, email, password_digest, created_at, updated_at) VALUES (#{user.id}, '#{user[:email]}', '#{user.password_digest}', NOW(), NOW())")
    end
  end
end
