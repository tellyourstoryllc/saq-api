class EmoticonSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :image_data
end
