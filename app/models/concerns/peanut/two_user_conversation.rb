module Peanut::TwoUserConversation
  extend ActiveSupport::Concern
  include Redis::Objects
  include Peanut::Conversation


  included do
    attr_accessor :id, :created_at, :sender_id, :recipient_id

    hash_key :attrs

    validates :sender_id, :recipient_id, presence: true
    validate :not_blocked?

    def initialize(attributes = {})
      attributes = attributes.with_indifferent_access
      super(attributes)
      self.id = attributes[:id]

      if id.present?
        sid, rid = id.split('-')
        self.sender_id ||= sid
        self.recipient_id ||= rid
        to_int(:created_at)
      end
    end

    def id
      @id ||= self.class.id_for_user_ids(sender_id, recipient_id)
    end

    def sender
      @sender ||= User.find_by(id: sender_id) if sender_id
    end

    def recipient
      @recipient ||= User.find_by(id: recipient_id) if recipient_id
    end

    def self.id_for_user_ids(sender_id, recipient_id)
      return if sender_id.blank? || recipient_id.blank?

      lower_id, higher_id = *[sender_id, recipient_id].sort!
      "#{lower_id}-#{higher_id}"
    end

    def fetched_member_ids
      [sender_id, recipient_id].compact.uniq
    end

    # Find the users seprately so it'll use AR cache in most cases
    def members(options = {})
      fetched_member_ids.map{ |id| User.find_by(id: id) }
    end

    def authorized?(user)
      user && (user.id == sender_id || user.id == recipient_id)
    end

    def blocked?
      User.blocked?(sender, recipient)
    end

    def other_user_id(user)
      return if user.nil?

      if user.id == sender_id
        recipient_id
      elsif user.id == recipient_id
        sender_id
      end
    end

    def other_user(user)
      return if user.nil?

      if user.id == sender.id
        recipient
      elsif user.id == recipient.id
        sender
      end
    end


    private

    def not_blocked?
      errors.add(:base, "Sorry, you can't message that user.") if blocked?
    end
  end
end
