class SnapMailer < BaseMailer
  def new_snap(recipient, sender)
    @recipient = recipient
    @sender = sender

    id = OneToOne.id_for_user_ids(@recipient.id, @sender.id)
    @url = Rails.configuration.app['web']['url'] + "/chat/#{id}?invite_channel=email"
    subject = "#{@sender.username} sent you a snap"

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end
end
