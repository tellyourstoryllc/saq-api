class CreateApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.integer :user_id, null: false
      t.column :token, 'CHAR(32)', null: false
      t.timestamps

      t.index [:token, :user_id]
    end
  end
end
