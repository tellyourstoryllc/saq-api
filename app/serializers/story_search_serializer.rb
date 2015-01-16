class StorySearchSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :permission, :source, :status, :has_face, :tags


  def has_face
    case object.has_face
    when 'yes' then true
    when 'no' then false
    else nil
    end
  end

  def created_at
    unix_timestamp = object.snapchat_created_at || object.created_at
    Time.zone.at(unix_timestamp).strftime("%Y-%m-%dT%H:%M:%S%z") if unix_timestamp
  end
end
