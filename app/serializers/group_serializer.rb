class GroupSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :creator_id, :name, :join_url, :admin_ids, :member_ids

  def join_url
    join_group_url(object.join_code) if object.join_code.present?
  end

  def include_admin_ids?
    object.creator_id == current_user.id
  end

  def admin_ids
    object.admin_ids.map(&:to_i)
  end

  def member_ids
    object.member_ids.map(&:to_i)
  end
end
