class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :status, :status_text, :idle_duration, :client_type, :avatar_url

  def name
    object.name if current_user && current_user.contact?(object)
  end

  def status
    if current_user && current_user.contact?(object)
      object.computed_status
    else
      'unavailable'
    end
  end

  def status_text
    object.status_text if current_user && current_user.contact?(object)
  end

  def idle_duration
    object.idle_duration if current_user && current_user.contact?(object)
  end

  def client_type
    if current_user && current_user.contact?(object)
      object.computed_client_type
    else
      'web'
    end
  end

  def avatar_url
    if current_user && current_user.contact?(object)
      object.avatar_url
    else
      AvatarImage.new.image.thumb.default_url
    end
  end

  def include_token?
    respond_to?(:current_user) && current_user.try(:id) == id
  end
end
