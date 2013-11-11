class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :token, :name, :status, :status_text, :idle_duration, :avatar_url

  def status
    object.computed_status
  end

  def include_token?
    respond_to?(:current_user) && current_user.try(:id) == id
  end
end
