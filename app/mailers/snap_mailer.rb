class SnapMailer < BaseMailer
  def new_snap(recipient, sender)
    @recipient = recipient
    @sender = sender

    id = OneToOne.id_for_user_ids(@recipient.id, @sender.id)
    @url = Rails.configuration.app['web']['url'] + "/chat/#{id}?invite_channel=email"
    subject = "#{@sender.username} sent you a snap"

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end

  def missed_sent_snaps(user)
    @user = user
    @url = Rails.configuration.app['web']['url'] + "/missed_sent_snaps?invite_channel=email"
    subject = "Reminder: Sending messages from the Snapchat app prevents them from being saved by #{Rails.configuration.app['app_name']}"

    mail(to: @user.emails.map(&:email), subject: subject)
  end

  def missed_received_snaps(user)
    @user = user
    @url = Rails.configuration.app['web']['url'] + "/missed_received_snaps?invite_channel=email"
    subject = "Reminder: Viewing messages in the Snapchat app prevents them from being saved by #{Rails.configuration.app['app_name']}"

    mail(to: @user.emails.map(&:email), subject: subject)
  end

  def unviewed_snaps(user, messages)
    @user = user
    @messages = messages
    @senders = @messages.map(&:user).uniq
    @url = Rails.configuration.app['web']['url'] + "/unviewed_snaps?invite_channel=email"

    friends_text = "s from #{@senders.size} of your friends" if @messages.size > 1
    subject = "You have #{@messages.size} unviewed snap#{friends_text} on #{Rails.configuration.app['app_name']}"

    mail(to: @user.emails.map(&:email), subject: subject)
  end
end
