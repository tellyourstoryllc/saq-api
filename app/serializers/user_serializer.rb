class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :status, :status_text,
    :idle_duration, :client_type, :avatar_url, :avatar_video_url, :phone_verification_token,
    :replaced_user_ids, :replaced_by_user_id, :deactivated

  def status
    if contacts?
      object.computed_status
    else
      'unavailable'
    end
  end

  def status_text
    object.status_text if contacts?
  end

  def idle_duration
    object.idle_duration if contacts?
  end

  def client_type
    if contacts?
      object.computed_client_type
    else
      'web'
    end
  end

  def avatar_url
    object.avatar_url if contacts?
  end

  def avatar_video_url
    object.avatar_video_url if contacts?
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


  private

  def owner?
    respond_to?(:current_user) && current_user.try(:id) == id
  end

  def contacts?
    scope && (scope.id == object.id || object.dynamic_contact?(scope))
  end
end
