FactoryGirl.define do
  factory :account do
    user_id 'asdf1234'
    emails_attributes { [{email: generate(:email_address)}] }

    trait :registered do
      registered true
    end

    trait :unregistered do
      registered false
    end
  end
end
