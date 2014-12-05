class CreateSnapInviteAdTranslations < ActiveRecord::Migration
  def up
    if SnapInviteAd.respond_to?(:create_translation_table!)
      SnapInviteAd.create_translation_table!(
        {
          name: {type: :string},
          media_url: {type: :string},
          text_overlay: {type: :string}
        },
        {migrate_data: true}
      )
    end
  end

  def down
    SnapInviteAd.drop_translation_table! if SnapInviteAd.respond_to?(:drop_translation_table!)
  end
end
