class Invite < ActiveRecord::Base
  include Peanut::Model

  attr_accessor :message

  before_validation :set_invite_token, :normalize_invited_phone, on: :create
  validates :sender_id, :recipient_id, presence: true
  validates :new_user, :can_log_in, inclusion: [true, false]
  after_create :send_invite, :send_mixpanel_event

  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'
  belongs_to :group


  # Send an invite if the recipient can't yet log in to the app
  # This way the person can get invites from multiple friends
  def send_invite?
    !can_log_in? && (invited_email.present? || invited_phone.present?) && !skip_sending?
  end

  def phone
    @phone ||= Phone.find_by(number: invited_phone) if invited_phone.present?
  end

  def mixpanel
    @mixpanel ||= MixpanelClient.new(sender)
  end

  def skip_sending=(skip)
    self[:skip_sending] = !!self.class.to_bool(skip)
  end


  private

  def set_invite_token
    return unless send_invite?

    chars = [*'a'..'z', *'A'..'Z', *0..9]

    loop do
      self.invite_token = invited_phone.present? ? Array.new(8){ chars.sample }.join : SecureRandom.hex
      break unless Invite.where(invite_token: invite_token).exists?
    end
  end

  def normalize_invited_phone
    self.invited_phone = Phone.normalize(invited_phone)
  end

  def send_invite
    return unless invite_token? && send_invite?

    if message
      InviteMailer.invite_via_message(sender, recipient, message, invited_email, invite_token).deliver! if invited_email.present?
      HookClient.invite_via_message(sender, recipient, message, invited_phone, invite_token) if invited_phone.present?
    else
      if invited_email.present?
        if group
          InviteMailer.invite_to_group(sender, recipient, group, invited_email, invite_token).deliver!
        else
          InviteMailer.invite_to_contacts(sender, recipient, invited_email, invite_token).deliver!
        end
      end

      if invited_phone.present?
        if group
          HookClient.invite_to_group(sender, recipient, group, invited_phone, invite_token)
        else
          HookClient.invite_to_contacts(sender, recipient, invited_phone, invite_token)
        end
      end
    end
  end

  def send_mixpanel_event
    mixpanel.sent_invite(self) if send_invite?
  end
end
