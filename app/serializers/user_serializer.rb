class UserSerializer < ActiveModel::Serializer
  attributes :object_type, :id, :name, :status, :status_text, :idle_duration, :contact_ids, :token

  def status
    object.computed_status
  end

  def include_contact_ids?
    current_user.id == id && object.include_contact_ids
  end

  def include_token?
    current_user.id == id
  end
end
