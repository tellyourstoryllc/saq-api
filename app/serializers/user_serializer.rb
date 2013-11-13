class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :status, :status_text, :idle_duration, :client_type, :avatar_url

  def status
    object.computed_status
  end

  def client_type
    object.computed_client_type
  end

  def include_token?
    respond_to?(:current_user) && current_user.try(:id) == id
  end
end
