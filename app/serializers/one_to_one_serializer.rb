class OneToOneSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :member_ids, :last_message_at

  def member_ids
    object.fetched_member_ids
  end
end
