class Invite < ActiveRecord::Base
  include Peanut::Model

  before_validation :set_invite_token, on: :create
  validates :sender_id, :recipient_id, presence: true
  validates :new_user, inclusion: [true, false]
  after_create :send_invite_email

  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_id'
  belongs_to :group


  private

  def set_invite_token
    return unless new_user && invited_email

    loop do
      self.invite_token = SecureRandom.hex
      break unless Invite.where(invite_token: invite_token).exists?
    end
  end

  def send_invite_email
    if group
      InviteMailer.invite_to_group(sender, recipient, group, invited_email, invite_token).deliver!
    else
      InviteMailer.invite_to_contacts(sender, recipient, invited_email, invite_token).deliver!
    end
  end
end
