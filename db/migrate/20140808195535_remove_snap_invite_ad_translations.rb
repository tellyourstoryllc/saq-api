class RemoveSnapInviteAdTranslations < ActiveRecord::Migration
  def up
    drop_table :snap_invite_ad_translations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
