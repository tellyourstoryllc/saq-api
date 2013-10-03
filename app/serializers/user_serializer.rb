class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :status, :status_text, :token
end
