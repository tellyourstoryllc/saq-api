class MessageSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :group_id, :one_to_one_id, :user_id, :rank, :text,
    :mentioned_user_ids, :attachment_url, :attachment_content_type, :attachment_preview_url,
    :attachment_preview_width, :attachment_preview_height, :attachment_metadata,
    :attachment_overlay_url, :attachment_overlay_text, :client_metadata,
    :likes_count, :original_message_id, :forward_message_id, :attachment_message_id,
    :actor_id, :created_at, :expires_at


  def likes_count
    object.cached_likes_count || object.likes.size
  end

  def created_at
    object.snapchat_created_at || object.created_at
  end
end
