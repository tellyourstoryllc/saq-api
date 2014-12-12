class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :status, :status_text,
    :idle_duration, :client_type, :avatar_url, :avatar_video_url, :avatar_video_preview_url,
    :replaced_user_ids, :replaced_by_user_id, :deactivated, :registered, :gender,
    :latitude, :longitude, :location_name, :friend_code


  def name
    object.name if acquaintance?
  end

  def username
    object.username if acquaintance?
  end

  # Don't need this in SCP
  def status
    return

    if friends?
      object.computed_status
    else
      'unavailable'
    end
  end

  # Don't need this in SCP
  def status_text
    return

    object.status_text if friends?
  end

  # Don't need this in SCP
  def idle_duration
    #object.idle_duration if friends?
  end

  # Don't need this in SCP
  def client_type
    #object.computed_client_type
  end

  def include_token?
    owner?
  end

  # Don't need this in SCP
  def replaced_user_ids
    #object.replaced_user_ids.members
  end

  # Don't need this in SCP
  def replaced_by_user_id
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
