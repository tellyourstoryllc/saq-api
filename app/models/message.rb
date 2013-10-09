class Message
  include Peanut::Model
  include ActiveModel::Model
  include ActiveModel::SerializerSupport
  include Redis::Objects

  attr_accessor :id, :group_id, :user_id, :text, :image_file,
    :message_image_id, :image_url, :created_at
  hash_key :attrs

  validates :group_id, :user_id, presence: true
  validate :text_under_limit?, :text_or_image_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super

    if id.present?
      attrs.all.each do |k,v|
        v = nil if v.blank?
        send("#{k}=", v)
      end

      to_int(:id, :group_id, :user_id, :created_at)
    end
  end

  def save
    return unless valid?

    generate_id
    save_message_image
    write_attrs
    add_to_group
  end

  def group
    @group ||= Group.find_by(id: group_id) if group_id
  end


  private

  def generate_id
    self.id ||= redis.incr('message_autoincrement_id')
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
      self.message_image_id = @message_image.id
    end

    self.attrs.bulk_set(id: id, group_id: group_id, user_id: user_id, text: text,
                        message_image_id: message_image_id, image_url: image_url, created_at: created_at)
  end

  def add_to_group
    group.message_ids[id] = id if group
  end
end
