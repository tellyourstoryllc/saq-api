class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :status, :status_text, :token

  def include_token?
    current_user.id == id
  end
end
