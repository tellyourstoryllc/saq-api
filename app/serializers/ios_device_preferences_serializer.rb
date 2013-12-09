class IosDevicePreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :client, :server_mention, :server_one_to_one
end
