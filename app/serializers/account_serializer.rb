class AccountSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :user_id, :one_to_one_wallpaper_url, :facebook_id, :time_zone, :needs_password


  def include_facebook_id?
    owner?
  end

  def include_time_zone?
    owner?
  end

  def include_needs_password?
    owner? && object.no_login_credentials?
  end

  def needs_password
    object.no_login_credentials?
  end


  private

  def owner?
    respond_to?(:current_user) && current_user.try(:id) == object.user_id
  end
end
