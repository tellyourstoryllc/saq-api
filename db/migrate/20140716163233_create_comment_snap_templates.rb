class CreateCommentSnapTemplates < ActiveRecord::Migration
  def change
    create_table :comment_snap_templates do |t|
      t.string :name, :title_overlay, :body_overlay, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
