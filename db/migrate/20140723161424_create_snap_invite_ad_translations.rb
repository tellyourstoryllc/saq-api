class CreateSnapInviteAdTranslations < ActiveRecord::Migration
  def up
    SnapInviteAd.create_translation_table!(
      {
        name: {type: :string},
        media_url: {type: :string},
        text_overlay: {type: :string}
      },
      {migrate_data: true}
    )
  end

  def down
    SnapInviteAd.drop_translation_table!
  end
end
