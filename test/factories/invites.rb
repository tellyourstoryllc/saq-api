FactoryGirl.define do
  factory :invite do
    sender_id 'asdf1234'
    recipient_id 'qwer5678'
    new_user true
    can_log_in false
  end
end
