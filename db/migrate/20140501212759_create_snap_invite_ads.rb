class CreateSnapInviteAds < ActiveRecord::Migration
  def change
    create_table :snap_invite_ads do |t|
      t.string :name
      t.string :image_url
      t.string :text_overlay
      t.timestamps
    end
  end
end
