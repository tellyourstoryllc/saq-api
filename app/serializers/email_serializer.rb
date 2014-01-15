class EmailSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :account_id, :user_id, :email
end
