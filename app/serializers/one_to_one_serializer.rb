class OneToOneSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :member_ids, :messages_count, :last_message_at,
    :last_seen_rank, :last_deleted_rank, :hidden, :pending

  def messages_count
    object.fetched_message_ids_count || object.message_ids.size
  end

  def member_ids
    object.fetched_member_ids
  end

  def pending
    object.pending?(scope)
  end
end
