class PublishGroupSerializer < GroupSerializer
  def include_last_seen_rank?
    false
  end

  def include_last_deleted_rank?
    false
  end

  def include_hidden?
    false
  end
end
