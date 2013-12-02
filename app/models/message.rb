class Message
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :group_id, :one_to_one_id, :user_id, :rank, :text, :attachment_file,
    :mentioned_user_ids, :message_attachment_id, :attachment_url, :attachment_content_type,
    :attachment_preview_url, :attachment_preview_width, :attachment_preview_height,
    :client_metadata, :created_at, :created_at_precise
  hash_key :attrs
  sorted_set :likes

  validates :user_id, presence: true
  validate :group_id_or_one_to_one_id?, :text_under_limit?, :text_or_attachment_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super
    to_int(:rank, :attachment_preview_width, :attachment_preview_height, :created_at) if id.present?
  end

  def save
    return unless valid?

    generate_id
    sanitize_mentioned_user_ids
    save_message_attachment
    write_attrs
    add_to_conversation
    set_rank

    true
  end

  def set_rank
    @rank = attrs[:rank] = conversation.message_ids.rank(id)
  end

  # In case a request for messages comes in between write_attrs and add_to_conversation
  def rank
    @rank ||= set_rank
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
    @mentioned_user_ids.present? ? @mentioned_user_ids.to_s.split(',') : []
  end

  def mentioned_all?
    mentioned_user_ids.include?('-1')
  end

  def mentioned_users
    if mentioned_user_ids.present?
      user_ids = mentioned_all? ? conversation.fetched_member_ids : mentioned_user_ids
      user_ids.delete(user_id)
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
    return if id.present?

    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z', *0..9]

    loop do
      self.id = Array.new(10){ chars.sample }.join
      break unless attrs.exists?
    end
  end

  def sanitize_mentioned_user_ids
    @mentioned_user_ids = @mentioned_user_ids.to_s.split(',') unless @mentioned_user_ids.is_a?(Array)

    if @mentioned_user_ids.blank? || conversation.nil?
      @mentioned_user_ids = nil
    else
      member_ids = ['-1'] # @all mention
      member_ids += conversation.fetched_member_ids

      sanitized_user_ids = @mentioned_user_ids & member_ids
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

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless text.present? || attachment_file.present?
  end

  def save_message_attachment
    return if attachment_file.blank?

    @message_attachment = MessageAttachment.new(message_id: id, message: self, attachment: attachment_file)
    @message_attachment.save!
  end

  def write_attrs
    self.created_at_precise = Time.current.to_f
    self.created_at = created_at_precise.to_i

    if @message_attachment && @message_attachment.attachment.present?
      self.attachment_url = @message_attachment.attachment.url
      self.attachment_content_type = @message_attachment.content_type
      self.attachment_preview_url = @message_attachment.preview_url
      self.attachment_preview_width = @message_attachment.preview_width
      self.attachment_preview_height = @message_attachment.preview_height
      self.message_attachment_id = @message_attachment.id
    end

    self.attrs.bulk_set(id: id, group_id: group_id, one_to_one_id: one_to_one_id, user_id: user_id,
                        text: text, mentioned_user_ids: @mentioned_user_ids, message_attachment_id: message_attachment_id,
                        attachment_url: attachment_url, attachment_content_type: attachment_content_type,
                        attachment_preview_url: attachment_preview_url, attachment_preview_width: attachment_preview_width,
                        attachment_preview_height: attachment_preview_height, client_metadata: client_metadata, created_at: created_at)
  end

  def add_to_conversation
    convo = conversation
    convo.message_ids[id] = created_at_precise if convo
  end
end
