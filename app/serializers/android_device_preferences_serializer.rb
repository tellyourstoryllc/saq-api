class AndroidDevicePreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :client, :server_mention, :server_one_to_one, :server_pushes_enabled
end
