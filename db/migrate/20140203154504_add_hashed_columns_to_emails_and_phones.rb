class AddHashedColumnsToEmailsAndPhones < ActiveRecord::Migration
  def change
    add_column :emails, :hashed_email,'CHAR(64)', null: false, after: 'email'
    Email.find_each(&:save!)
    add_index :emails, :hashed_email, unique: true

    add_column :phones, :hashed_number, 'CHAR(64)', null: false, after: 'number'
    Phone.find_each(&:save!)
    add_index :phones, :hashed_number, unique: true
  end
end
