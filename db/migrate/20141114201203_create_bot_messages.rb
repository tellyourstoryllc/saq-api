class CreateBotMessages < ActiveRecord::Migration
  def change
    create_table :bot_messages do |t|
      t.column :user_id, 'CHAR(8)', null: false
      t.column :message_id, 'CHAR(10)', null: false
      t.text :text
      t.string :attachment_url
      t.string :attachment_preview_url
      t.timestamps
    end
  end
end
