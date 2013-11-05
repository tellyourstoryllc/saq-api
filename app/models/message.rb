class Message
  include Peanut::Model
  include Peanut::RedisModel
  include ActiveModel::Model
  include ActiveModel::SerializerSupport
  include Redis::Objects

  attr_accessor :id, :group_id, :user_id, :text, :image_file,
    :mentioned_user_ids, :message_image_id, :image_url, :image_thumb_url, :created_at
  hash_key :attrs
  sorted_set :likes

  validates :group_id, :user_id, presence: true
  validate :text_under_limit?, :text_or_image_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super
    to_int(:id, :group_id, :user_id, :created_at) if id.present?
  end

  def save
    return unless valid?

    generate_id
    sanitize_mentioned_user_ids
    save_message_image
    write_attrs
    add_to_group
  end

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end

  def group
    @group ||= Group.find_by(id: group_id) if group_id
  end

  def mentioned_user_ids
    @mentioned_user_ids.present? ? @mentioned_user_ids.to_s.split(',').map(&:to_i) : []
  end

  def mentioned_all?
    mentioned_user_ids.include?(-1)
  end

  def mentioned_users
    if mentioned_user_ids.present?
      user_ids = mentioned_all? ? group.member_ids.members : mentioned_user_ids
      User.where(id: user_ids)
    else
      []
    end
  end

  def like(user)
    likes[user.id] = Time.current.to_f unless likes.member?(user.id)
  end

  def unlike(user)
    likes.delete(user.id)
  end


  private

  def generate_id
    self.id ||= redis.incr('message_autoincrement_id')
  end

  def sanitize_mentioned_user_ids
    @mentioned_user_ids = @mentioned_user_ids.to_s.split(',')

    if @mentioned_user_ids.blank? || group.nil?
      @mentioned_user_ids = nil
    else
      member_ids = [-1] # @all mention
      member_ids += group.member_ids.members.map(&:to_i)

      sanitized_user_ids = @mentioned_user_ids.map(&:to_i) & member_ids
      @mentioned_user_ids = sanitized_user_ids.join(',')
    end
  end

  def text_under_limit?
    errors.add(:base, "Text is too long (maximum is #{TEXT_LIMIT} characters)") if text.present? && text.size > TEXT_LIMIT
  end

  def text_or_image_set?
    errors.add(:base, "Either text or an image is required.") unless text.present? || image_file.present?
  end

  def save_message_image
    return if image_file.blank?

    @message_image = MessageImage.new(message_id: id, message: self, image: image_file)
    @message_image.save!
  end

  def write_attrs
    self.created_at = Time.current.to_i

    if @message_image && @message_image.image.present?
      self.image_url = @message_image.image.url
      self.image_thumb_url = @message_image.image.thumb.url
      self.message_image_id = @message_image.id
    end

    self.attrs.bulk_set(id: id, group_id: group_id, user_id: user_id, text: text, mentioned_user_ids: @mentioned_user_ids,
                        message_image_id: message_image_id, image_url: image_url, image_thumb_url: image_thumb_url, created_at: created_at)
  end

  def add_to_group
    group.message_ids[id] = id if group
  end
end
