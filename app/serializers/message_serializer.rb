class MessageSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :group_id, :one_to_one_id, :user_id, :text,
    :mentioned_user_ids, :image_url, :image_thumb_url, :likes_count, :created_at

  def likes_count
    object.likes.size
  end
end
