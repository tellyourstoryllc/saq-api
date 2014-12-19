class CreateFlagReasons < ActiveRecord::Migration
  def change
    create_table :flag_reasons do |t|
      t.string :text, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
