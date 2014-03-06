class AddVerificationCodeToPhones < ActiveRecord::Migration
  def change
    add_column :phones, :verification_code, 'CHAR(4)'
  end
end
