class OneToOne
  include Peanut::RedisModel
  include ActiveModel::Model
  include ActiveModel::SerializerSupport
  include Redis::Objects
  include Peanut::Conversation

  attr_accessor :id, :created_at, :sender_id, :recipient_id

  hash_key :attrs
  sorted_set :message_ids

  validates :sender_id, :recipient_id, presence: true
  validate :users_are_contacts?


  def initialize(attributes = {})
    super
    self.id = attributes[:id]

    if id.present?
      sid, rid = id.split('-')
      self.sender_id ||= sid
      self.recipient_id ||= rid
      to_int(:sender_id, :recipient_id, :created_at)
    end
  end

  def id
    @id ||= self.class.id_for_user_ids(sender_id, recipient_id)
  end

  def self.id_for_user_ids(sender_id, recipient_id)
    return if sender_id.blank? || recipient_id.blank?

    lower_id, higher_id = *[sender_id.to_i, recipient_id.to_i].sort!
    "#{lower_id}-#{higher_id}"
  end

  def sender
    @sender ||= User.find_by(id: sender_id) if sender_id
  end

  def recipient
    @recipient ||= User.find_by(id: recipient_id) if recipient_id
  end

  def fetched_member_ids
    [sender_id, recipient_id].compact.map(&:to_i).uniq
  end

  # Find the users seprately so it'll use AR cache in most cases
  def members
    fetched_member_ids.map{ |id| User.find_by(id: id) }
  end

  def save
    return unless valid?

    write_attrs
    add_members
  end

  def authorized?(user)
    user && (user.id == sender_id || user.id == recipient_id)
  end

  def other_user(user)
    if user.id == sender.id
      recipient
    elsif user.id == recipient.id
      sender
    end
  end


  private

  def users_are_contacts?
    errors.add(:base, "Users must be contacts to send private messages.") unless User.contacts?(sender, recipient)
  end

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, created_at: created_at)
  end

  def add_members
    redis.pipelined do
      sender.one_to_one_ids << id
      sender.one_to_one_user_ids << recipient.id

      recipient.one_to_one_ids << id
      recipient.one_to_one_user_ids << sender.id
    end
  end
end
