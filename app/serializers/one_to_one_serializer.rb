class OneToOneSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :member_ids

  def member_ids
    object.fetched_member_ids
  end
end
