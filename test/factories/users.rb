FactoryGirl.define do
  factory :user do
    sequence(:username){ |n| "JohnDoe_#{n}" }

    trait :male do
      gender 'male'
    end

    trait :female do
      gender 'female'
    end

    trait :deactivated do
      deactivated true
    end

    factory :registered_user do
      after(:create) do |u|
        FactoryGirl.create(:account, :registered, user: u)
      end
    end
  end
end
