class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :status, :status_text, :idle_duration, :token

  def status
    object.computed_status
  end

  def include_token?
    respond_to?(:current_user) && current_user.try(:id) == id
  end
end
