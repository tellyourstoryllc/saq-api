class CreateVideoModerationRejectReasons < ActiveRecord::Migration
  def change
    create_table :video_moderation_reject_reasons do |t|
      t.string :title, null: false
      t.text :message_to_user
      t.boolean :default_reason, null: false, default: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
