class StoriesList
  include Peanut::RedisModel

  # id is the creator's user id
  attr_accessor :id, :viewer_id
  def no_attrs; true end

  validate :not_blocked?


  def creator
    @creator ||= User.find_by(id: id) if id
  end

  def viewer
    @viewer ||= User.find_by(id: viewer_id) if viewer_id
  end

  def authorized?(user)
    user && (user.id == id || user.id == viewer_id)
  end

  def blocked?
    User.blocked?(creator, viewer)
  end

  def other_user_id(user)
    return if user.nil?

    if user.id == id
      viewer_id
    elsif user.id == viewer_id
      id
    end
  end

  def other_user(user)
    return if user.nil?

    if user.id == creator.id
      viewer
    elsif user.id == viewer.id
      creator
    end
  end


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't see that user's stories.") if blocked?
  end
end
