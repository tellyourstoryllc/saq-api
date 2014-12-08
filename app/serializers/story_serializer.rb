class StorySerializer < MessageSerializer
  attributes :snapchat_media_id, :comments_count, :comments_disabled

  def comments_count
    object.comment_ids.size
  end

  def comments_disabled
    object.comments_disabled?
  end
end
