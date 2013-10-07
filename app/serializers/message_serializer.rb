class MessageSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :group_id, :user_id, :text, :created_at
end
