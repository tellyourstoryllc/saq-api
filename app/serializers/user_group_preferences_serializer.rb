class UserGroupPreferencesSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :group_id, :server_all_messages_mobile_push, :created_at
end
