class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :status, :status_text,
    :idle_duration, :client_type, :avatar_url, :avatar_video_url, :avatar_video_preview_url,
    :phone_verification_token, :replaced_user_ids, :replaced_by_user_id, :deactivated, :registered

  def status
    if friends?
      object.computed_status
    else
      'unavailable'
    end
  end

  def status_text
    object.status_text if friends?
  end

  def idle_duration
    object.idle_duration if friends?
  end

  def client_type
    if friends?
      object.computed_client_type
    else
      'web'
    end
  end

  def include_token?
    owner?
  end

  def include_phone_verification_token?
    owner? && !current_user.phones.where(verified: true).exists? && !Rails.env.test?
  end

  def phone_verification_token
    object.fetch_phone_verification_token
  end

  def replaced_user_ids
    object.replaced_user_ids.members
  end

  def registered
    if User::BLACKLISTED_USERNAMES.include?(object.username)
      true
    elsif object.uninstalled
      false
    else
      object.registered
    end
  end


  private

  def owner?
    respond_to?(:current_user) && current_user.try(:id) == id
  end

  def friends?
    scope && (scope.id == object.id || object.dynamic_friend?(scope))
  end
end
