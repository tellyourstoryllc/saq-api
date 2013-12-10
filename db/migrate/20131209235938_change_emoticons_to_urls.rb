class ChangeEmoticonsToUrls < ActiveRecord::Migration
  def up
    Emoticon.update_all(image_data: '')

    rename_column :emoticons, :image_data, :image
    change_column :emoticons, :image, :string, null: false # for carrierwave
    add_column :emoticons, :local_file_path, :string, null: false
    add_column :emoticons, :sha1, :string, null: false
  end

  def down
    Emoticon.update_all(image: '')

    rename_column :emoticons, :image, :image_data
    change_column :emoticons, :image_data, 'MEDIUMTEXT', null: false
    remove_column :emoticons, :local_file_path
    remove_column :emoticons, :sha1
  end
end
