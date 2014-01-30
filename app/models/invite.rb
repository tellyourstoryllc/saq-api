class Invite < ActiveRecord::Base
  include Peanut::Model

  before_validation :set_invite_token, on: :create
  validates :sender_id, :recipient_id, presence: true
  validates :new_user, inclusion: [true, false]
  after_create :send_invite

  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'
  belongs_to :group


  def invited_new_user?
    new_user && (invited_email.present? || invited_phone.present?)
  end


  private

  def set_invite_token
    return unless invited_new_user?

    chars = [*'a'..'z', *'A'..'Z', *0..9]

    loop do
      self.invite_token = invited_phone.present? ? Array.new(8){ chars.sample }.join : SecureRandom.hex
      break unless Invite.where(invite_token: invite_token).exists?
    end
  end

  def send_invite
    return unless invited_new_user?

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
