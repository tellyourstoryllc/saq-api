class InviteMailer < BaseMailer
  def invite_to_contacts(sender, recipient, email, invite_token)
    @sender = sender
    @recipient = recipient

    one_to_one_id = OneToOne.id_for_user_ids(sender.id, recipient.id)
    @url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"

    mail(to: email, subject: "#{@sender.public_username || 'Somebody'} added you as a contact")
  end

  def invite_to_group(sender, recipient, group, email, invite_token)
    @sender = sender
    @recipient = recipient
    @group = group
    @url = Rails.configuration.app['web']['url'].dup
    @url << (invite_token.present? ? "/i/#{invite_token}" : "/rooms/#{@group.id}")

    to = email.present? ? email : @recipient.emails.map(&:email)

    mail(to: to, subject: "#{@sender.public_username || 'Somebody'} added you to the room \"#{@group.name}\"")
  end

  def invite_via_message(sender, recipient, message, email, invite_token)
    @sender = sender
    @recipient = recipient
    @message = message
    @media_type = @message.message_attachment.try(:friendly_media_type) || 'a message'
    @expires_text = " that expires in #{distance_of_time_in_words(Time.current, Time.zone.at(@message.expires_at))}" if @message.expires_at

    one_to_one_id = OneToOne.id_for_user_ids(sender.id, recipient.id)
    @url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"

    mail(to: email, subject: "#{@sender.public_username || 'Somebody'} just sent you #{@media_type}#{@expires_text}")
  end
end
