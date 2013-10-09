class MessageSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :group_id, :user_id, :text, :image_url, :created_at
end
