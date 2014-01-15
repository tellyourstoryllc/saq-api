class MoveEmailFromAccountsToEmails < ActiveRecord::Migration
  def up
    Account.find_each do |a|
      Email.create!(account_id: a.id, user_id: a.user_id, email: a.email)
    end

    remove_column :accounts, :email
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
