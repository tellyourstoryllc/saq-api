class StorySearchSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :tags


  def created_at
    unix_timestamp = object.snapchat_created_at || object.created_at
    Time.zone.at(unix_timestamp).strftime("%Y-%m-%dT%H:%M:%S%z") if unix_timestamp
  end

  def tags
    text = object.attachment_overlay_text
    text.present? ? text.scan(/#([\w-]+)/).flatten : []
  end
end
