class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :token
end
