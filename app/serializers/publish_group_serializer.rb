class PublishGroupSerializer < GroupSerializer
  def include_last_seen_rank?
    false
  end
end
