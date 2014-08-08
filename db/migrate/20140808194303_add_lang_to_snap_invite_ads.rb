class AddLangToSnapInviteAds < ActiveRecord::Migration
  def change
    add_column :snap_invite_ads, :lang, :string, null: false, default: 'en'
  end
end
