FactoryGirl.define do
  factory :email do
    account_id 1
    user_id 'asdf1234'
    sequence(:email){ |n| "email#{n}@example.com" }
  end
end
