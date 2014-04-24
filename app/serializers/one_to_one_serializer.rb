class OneToOneSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :member_ids, :last_message_at,
    :last_seen_rank, :last_deleted_rank, :hidden

  def member_ids
    object.fetched_member_ids
  end
end
