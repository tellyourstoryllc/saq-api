FactoryGirl.define do
  sequence :email_address do |n|
    "email#{n}@example.com"
  end

  factory :email do
    account_id 1
    user_id 'asdf1234'
    email { generate(:email_address) }
  end
end
