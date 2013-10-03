FactoryGirl.define do
  factory :user do
    name 'John Doe'
    sequence(:email){ |n| "user#{n}@example.com" }
    password 'asdf'
  end
end
