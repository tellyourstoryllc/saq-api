class RemoveSnapInviteAdTranslations < ActiveRecord::Migration
  def up
    drop_table :snap_invite_ad_translations if ActiveRecord::Base.connection.table_exists?(:snap_invite_ad_translations)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
