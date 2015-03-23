class StorySerializer < MessageSerializer
  attributes :snapchat_media_id, :latitude, :longitude, :source, :permission, :has_face, :status, :shareable_to

  def latitude
    latitude = object.latitude
    return if latitude.blank?

    if owner?
      latitude.to_f
    else
      latitude.to_f.round(2)
    end
  end

  def longitude
    longitude = object.longitude
    return if longitude.blank?

    if owner?
      longitude.to_f
    else
      longitude.to_f.round(2)
    end
  end

  def include_permission?
    owner?
  end

  def include_status?
    owner?
  end
end
