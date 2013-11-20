class ChangeMessageIdsToStrings < ActiveRecord::Migration
  def up
    change_column :message_images, :message_id, 'CHAR(10)', null: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
