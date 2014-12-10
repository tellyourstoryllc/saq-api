class StorySerializer < MessageSerializer
  attributes :snapchat_media_id, :latitude, :longitude

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


  private

  def owner?
    respond_to?(:scope) && scope.try(:id) == user_id
  end
end
