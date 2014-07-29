class AddEmailSubjectAndEmailBodyToDripNotifications < ActiveRecord::Migration
  def change
    add_column :drip_notifications, :email_subject, :string, null: false
    add_column :drip_notifications, :email_body, :text, null: false
  end
end
