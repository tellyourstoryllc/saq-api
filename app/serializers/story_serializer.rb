class StorySerializer < MessageSerializer
  attributes :snapchat_media_id, :comments_count

  def forwards_count; 0 end

  def comments_count
    object.comment_ids.size
  end
end
