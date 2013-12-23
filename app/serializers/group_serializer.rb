class GroupSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :join_url, :topic, :avatar_url,
    :wallpaper_url, :admin_ids, :member_ids, :last_message_at, :last_seen_rank, :created_at

  def join_url
    "#{Rails.configuration.app['web']['url']}/join/#{object.join_code}" if object.join_code.present?
  end

  def admin_ids
    object.admin_ids.members.sort
  end

  def member_ids
    object.fetched_member_ids.sort
  end

  def created_at
    object.created_at.try(:to_i)
  end
end
