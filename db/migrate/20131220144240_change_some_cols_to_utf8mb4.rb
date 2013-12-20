class ChangeSomeColsToUtf8mb4 < ActiveRecord::Migration
  def up
    execute 'ALTER TABLE groups MODIFY topic VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL'
    execute 'ALTER TABLE rapns_notifications MODIFY alert VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL'
    execute 'ALTER TABLE users MODIFY status_text VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL'
  end

  def down
    execute 'ALTER TABLE users MODIFY status_text VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL'
    execute 'ALTER TABLE rapns_notifications MODIFY alert VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL'
    execute 'ALTER TABLE groups MODIFY topic VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL'
  end
end
