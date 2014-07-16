class CreateLikeSnapTemplates < ActiveRecord::Migration
  def change
    create_table :like_snap_templates do |t|
      t.string :name, :text_overlay, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
