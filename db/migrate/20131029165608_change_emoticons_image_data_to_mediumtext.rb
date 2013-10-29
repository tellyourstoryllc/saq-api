class ChangeEmoticonsImageDataToMediumtext < ActiveRecord::Migration
  def up
    change_column :emoticons, :image_data, :text, null: false, limit: 10.megabytes
  end
  def down
    change_column :emoticons, :image_data, :text, null: false
  end
end
