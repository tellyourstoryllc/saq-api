class Message
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :group_id, :one_to_one_id, :user_id, :text, :image_file,
    :mentioned_user_ids, :message_image_id, :image_url, :image_thumb_url, :client_metadata, :created_at
  hash_key :attrs
  sorted_set :likes

  validates :user_id, presence: true
  validate :group_id_or_one_to_one_id?, :text_under_limit?, :text_or_image_set?

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
    add_to_conversation

    true
  end

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end

  def group
    @group ||= Group.find_by(id: group_id) if group_id
  end

  def one_to_one
    @one_to_one ||= OneToOne.new(id: one_to_one_id) if one_to_one_id
  end

  def mentioned_user_ids
    @mentioned_user_ids.present? ? @mentioned_user_ids.to_s.split(',').map(&:to_i) : []
  end

  def mentioned_all?
    mentioned_user_ids.include?(-1)
  end

  def mentioned_users
    if mentioned_user_ids.present?
      user_ids = mentioned_all? ? conversation.fetched_member_ids : mentioned_user_ids
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

  def conversation
    group || one_to_one
  end


  private

  def generate_id
    self.id ||= redis.incr('message_autoincrement_id')
  end

  def sanitize_mentioned_user_ids
    @mentioned_user_ids = @mentioned_user_ids.to_s.split(',') unless @mentioned_user_ids.is_a?(Array)

    if @mentioned_user_ids.blank? || conversation.nil?
      @mentioned_user_ids = nil
    else
      member_ids = [-1] # @all mention
      member_ids += conversation.fetched_member_ids

      sanitized_user_ids = @mentioned_user_ids.map(&:to_i) & member_ids
      @mentioned_user_ids = sanitized_user_ids.join(',')
    end
  end

  def group_id_or_one_to_one_id?
    attrs = [group_id, one_to_one_id]
    errors.add(:base, "Must specify exactly one of group_id or one_to_one_id.") if attrs.all?(&:blank?) || attrs.all?(&:present?)
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

    self.attrs.bulk_set(id: id, group_id: group_id, one_to_one_id: one_to_one_id, user_id: user_id,
                        text: text, mentioned_user_ids: @mentioned_user_ids, message_image_id: message_image_id,
                        image_url: image_url, image_thumb_url: image_thumb_url, client_metadata: client_metadata, created_at: created_at)
  end

  def add_to_conversation
    convo = conversation
    convo.message_ids[id] = id if convo
  end
end
