class MakeNameAndUsernameUtf8mb4 < ActiveRecord::Migration
  def up
    execute 'ALTER TABLE users MODIFY name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL'
  end

  def down
    execute 'ALTER TABLE users MODIFY name VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL'
  end
end
