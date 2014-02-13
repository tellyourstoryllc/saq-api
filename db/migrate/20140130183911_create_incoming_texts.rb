class CreateIncomingTexts < ActiveRecord::Migration
  def change
    create_table :incoming_texts do |t|
      t.text :raw_body
      t.string :from, :recipient, :text, :message_id
      t.datetime :timestamp
      t.timestamps
    end
  end
end
