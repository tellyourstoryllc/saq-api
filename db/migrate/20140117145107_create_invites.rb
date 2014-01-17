class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.column :sender_id, 'CHAR(8)', null: false
      t.column :recipient_id, 'CHAR(8)', null: false
      t.string :invited_email
      t.boolean :new_user, null: false
      t.column :group_id, 'CHAR(8)'
      t.string :invite_token, null: false
      t.timestamps

      t.index :sender_id
      t.index :recipient_id
      t.index :group_id
      t.index :invite_token
    end
  end
end
