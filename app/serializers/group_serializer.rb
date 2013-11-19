class GroupSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :join_url, :topic, :wallpaper_url, :admin_ids, :member_ids

  def join_url
    "#{Rails.configuration.app['web']['url']}/join/#{object.join_code}" if object.join_code.present?
  end

  def admin_ids
    object.admin_ids.members.sort
  end

  def member_ids
    object.fetched_member_ids.sort
  end
end
