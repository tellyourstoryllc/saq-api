class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :avatar_url, :avatar_video_url,
    :avatar_video_preview_url, :deactivated, :registered, :gender, :latitude, :longitude,
    :location_name, :friend_code


  def include_token?
    owner?
  end

  def name
    object.name if acquaintance?
  end

  def username
    object.username if acquaintance?
  end

  def avatar_url
    object.avatar_url unless object.avatar_image.try(:censored?)
  end

  def avatar_video_url
    object.avatar_video_url unless object.avatar_video.try(:censored?)
  end

  def avatar_video_preview_url
    object.avatar_video_preview_url unless object.avatar_video.try(:censored?)
  end

  def registered
    if Settings.get_list(:blacklisted_usernames).include?(object.username)
      true
    elsif object.uninstalled
      false
    else
      object.registered
    end
  end

  def latitude
    latitude = object.latitude
    return if latitude.blank?

    if owner?
      latitude.to_f
    else
      latitude.to_f.round(2)
    end
  end

  def longitude
    longitude = object.longitude
    return if longitude.blank?

    if owner?
      longitude.to_f
    else
      longitude.to_f.round(2)
    end
  end

  def include_friend_code?
    owner?
  end


  private

  def owner?
    respond_to?(:current_user) && current_user.try(:id) == id
  end

  def acquaintance?
    return @acquaintance if defined?(@acquaintance)
    @acquaintance = scope && (scope.id == object.id || scope.acquaintance?(object))
  end
end
