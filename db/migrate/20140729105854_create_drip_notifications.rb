class CreateDripNotifications < ActiveRecord::Migration
  def change
    create_table :drip_notifications do |t|
      t.string :name, :push_text, null: false
      t.integer :rank, null: false
      t.column :client, "ENUM('ios', 'android')", null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
