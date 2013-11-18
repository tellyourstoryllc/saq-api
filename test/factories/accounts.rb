FactoryGirl.define do
  factory :account do
    user_id 1
    sequence(:email){ |n| "account#{n}@example.com" }
    password 'asdf'
  end
end
