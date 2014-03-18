class AddMoreInfoToIncomingTexts < ActiveRecord::Migration
  def change
    add_column :incoming_texts, :callback_type, :string
    add_column :incoming_texts, :error_code, :integer
  end
end
