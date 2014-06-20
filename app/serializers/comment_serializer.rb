class CommentSerializer < MessageSerializer
  attributes :collection_id, :collection_type

  def likes_count; 0 end
  def forwards_count; 0 end
end
