FactoryGirl.define do
  factory :account do
    user_id 'asdf1234'
    sequence(:email){ |n| "account#{n}@example.com" }
    password 'asdf'
  end
end
