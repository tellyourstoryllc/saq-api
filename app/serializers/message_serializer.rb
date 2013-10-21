class MessageSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :group_id, :user_id, :text, :mentioned_user_ids, :image_url, :image_thumb_url, :created_at
end
