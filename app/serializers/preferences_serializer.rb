class PreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :client_web, :client_ios, :server_mention_email, :server_mention_ios,
    :server_one_to_one_email, :server_one_to_one_ios, :created_at
end
