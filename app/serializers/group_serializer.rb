class GroupSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :creator_id, :name, :join_url

  def join_url
    join_group_url(object.join_code) if object.join_code.present?
  end
end
