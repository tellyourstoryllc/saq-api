class UserPreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :client_web, :server_mention_email, :server_one_to_one_email
end
