class InviteMailer < BaseMailer
  def invite_to_contacts(sender, recipient, email, invite_token)
    @sender = sender
    @recipient = recipient

    one_to_one_id = OneToOne.id_for_user_ids(sender.id, recipient.id)
    @url = Rails.configuration.app['web']['url'] + "/rooms/#{one_to_one_id}?invite_token=#{invite_token}"

    mail(to: email, subject: "#{@sender.name} added you as a contact")
  end

  def invite_to_group(sender, recipient, group, email, invite_token)
    @sender = sender
    @recipient = recipient
    @group = group
    @url = Rails.configuration.app['web']['url'] + "/rooms/#{@group.id}"
    @url << "?invite_token=#{invite_token}" if invite_token.present?

    to = email.present? ? email : @recipient.emails.map(&:email)

    mail(to: to, subject: "#{@sender.name} added you to the room \"#{@group.name}\"")
  end
end
