class CreateVideoRejections < ActiveRecord::Migration
  def change
    create_table :video_rejections do |t|
      t.column :story_id, 'CHAR(10)', null: false
      t.integer :video_moderation_reject_reason_id
      t.string :custom_message_to_user
      t.timestamps
    end
  end
end
