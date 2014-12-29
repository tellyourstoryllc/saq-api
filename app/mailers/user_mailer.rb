class UserMailer < BaseMailer
  def new_friend(recipient, friend, mutual)
    @recipient = recipient
    @friend = friend

    @url = Rails.configuration.app['web']['url'] + "/new_friend?invite_channel=email"
    subject = "#{@friend.public_username || 'Somebody'} just friended you#{' back' if mutual}!"

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end
end
