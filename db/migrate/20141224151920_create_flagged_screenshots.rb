class CreateFlaggedScreenshots < ActiveRecord::Migration
  def change
    create_table :flagged_screenshots do |t|
      t.column :user_id, 'CHAR(8)', null: false
      t.column :flagger_id, 'CHAR(8)', null: false
      t.string :image, :uuid, null: false
      t.column :status, "ENUM('pending','review','normal','censored')", null: false
      t.timestamps

      t.index :user_id
    end
  end
end
