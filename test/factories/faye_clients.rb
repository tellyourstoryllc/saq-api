FactoryGirl.define do
  factory :faye_client do
    sequence(:id)
    exists '1'
    user_id 'asdf1234'
    client_type 'web'
  end
end
