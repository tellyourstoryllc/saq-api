class Message
  include Peanut::Model
  include ActiveModel::Model
  include ActiveModel::SerializerSupport
  include Redis::Objects

  attr_accessor :id, :group_id, :user_id, :text, :created_at
  hash_key :attrs

  validates :group_id, :user_id, :text, presence: true
  validate :text_under_limit?

  TEXT_LIMIT = 1_000


  def save
    return unless valid?

    write_attrs
    add_to_group
  end

  def group
    @group ||= Group.find_by(id: group_id) if group_id
  end


  private

  def generate_id
    redis.incr('message_autoincrement_id')
  end

  def text_under_limit?
    errors.add(:base, "Text is too long (maximum is #{TEXT_LIMIT} characters)") if text.present? && text.size > TEXT_LIMIT
  end

  def write_attrs
    self.id = generate_id
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, group_id: group_id, user_id: user_id, text: text, created_at: created_at)
  end

  def add_to_group
    group.message_ids[id] = id if group
  end
end
