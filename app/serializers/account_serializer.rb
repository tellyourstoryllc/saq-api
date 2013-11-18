class AccountSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :email, :one_to_one_wallpaper_url

  def include_email?
    current_user.try(:id) == object.user_id
  end
end
