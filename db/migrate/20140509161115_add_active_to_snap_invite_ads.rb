class AddActiveToSnapInviteAds < ActiveRecord::Migration
  def change
    add_column :snap_invite_ads, :active, :boolean, null: false, default: true
  end
end
