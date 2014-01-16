class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :username, :status, :status_text, :idle_duration, :client_type, :avatar_url

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

  def include_token?
    respond_to?(:current_user) && current_user.try(:id) == id
  end


  private

  def contacts?
    current_user && (current_user.id == object.id || object.contact?(current_user))
  end
end
