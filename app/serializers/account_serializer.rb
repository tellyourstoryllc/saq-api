class AccountSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :one_to_one_wallpaper_url, :facebook_id, :time_zone

  def include_facebook_id?
    current_user.try(:id) == object.user_id
  end
end
