class RenameImageUrlInSnapInviteAds < ActiveRecord::Migration
  def change
    rename_column :snap_invite_ads, :image_url, :media_url
  end
end
