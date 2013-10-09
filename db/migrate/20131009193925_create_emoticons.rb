class CreateEmoticons < ActiveRecord::Migration
  def change
    create_table :emoticons do |t|
      t.string :name, null: false
      t.text :image_data, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
