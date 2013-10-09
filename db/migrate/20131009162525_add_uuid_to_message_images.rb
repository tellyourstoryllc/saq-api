class AddUuidToMessageImages < ActiveRecord::Migration
  def change
    add_column :message_images, :uuid, :string, after: :image, null: false
  end
end
