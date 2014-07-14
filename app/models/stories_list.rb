class StoriesList
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::Conversation
  include Peanut::StoriesCollection

  attr_accessor :id, :created_at, :creator_id, :viewer_id

  validates :creator_id, :viewer_id, presence: true
  validate :not_blocked?


  def initialize(attributes = {})
    attributes = attributes.with_indifferent_access
    super(attributes)
    self.id = attributes[:id]

    if id.present?
      cid, vid = id.split(':')
      self.creator_id ||= cid
      self.viewer_id ||= vid
      to_int(:created_at)
    end
  end

  def id
    @id ||= self.class.id_for_user_ids(creator_id, viewer_id)
  end

  def self.id_for_user_ids(creator_id, viewer_id)
    "#{creator_id}:#{viewer_id}" if creator_id.present? && viewer_id.present?
  end

  def creator
    @creator ||= User.find_by(id: creator_id) if creator_id
  end

  def viewer
    @viewer ||= User.find_by(id: viewer_id) if viewer_id
  end

  def fetched_member_ids
    [creator_id, viewer_id].compact.uniq
  end

  # Find the users seprately so it'll use AR cache in most cases
  def members(options = {})
    fetched_member_ids.map{ |id| User.find_by(id: id) }
  end

  def authorized?(user)
    user && (user.id == creator_id || user.id == viewer_id)
  end

  def blocked?
    User.blocked?(creator, viewer)
  end

  def other_user_id(user)
    return if user.nil?

    if user.id == creator_id
      viewer_id
    elsif user.id == viewer_id
      creator_id
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

  def save
    return unless valid?

    write_attrs
  end


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't see that user's stories.") if blocked?
  end

  def write_attrs
    self.created_at ||= Time.current.to_i
    self.attrs.bulk_set(id: id, creator_id: creator_id, viewer_id: viewer_id, created_at: created_at)
  end
end
