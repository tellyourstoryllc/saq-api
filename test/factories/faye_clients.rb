FactoryGirl.define do
  factory :faye_client do
    sequence(:id)
    user_id 'asdf1234'
    client_type 'web'
  end
end
