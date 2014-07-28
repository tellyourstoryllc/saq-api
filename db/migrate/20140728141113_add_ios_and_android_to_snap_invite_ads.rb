class AddIosAndAndroidToSnapInviteAds < ActiveRecord::Migration
  def change
    add_column :snap_invite_ads, :ios, :boolean, null: false, default: false
    add_column :snap_invite_ads, :android, :boolean, null: false, default: false
  end
end
