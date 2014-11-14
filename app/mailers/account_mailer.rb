class AccountMailer < BaseMailer
  def welcome(account)
    mail(to: account.emails.map(&:email), subject: "Welcome to #{Rails.configuration.app['app_name']}!")
  end

  def password_reset(account, token)
    @url = reset_password_url(token)
    mail(to: account.emails.map(&:email), subject: 'Password Reset Instructions')
  end

  def missing_password(account, token)
    @url = reset_password_url(token)
    mail(to: account.emails.map(&:email), subject: 'Set Your Password')
  end

  def arbitrary(recipient, subject, msg, options = {})
    options = options.with_indifferent_access

    @recipient = recipient
    @msg = msg
    @link_text = options[:link_text].presence || 'Click here to open the app now'
    @url = options[:url].presence || Rails.configuration.app['web']['url']

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end

  def widget_tutorial(recipient)
    @image_url = Rails.configuration.app['web']['url'] + '/images/widget-tutorial-e7c881a02eb962c0e6b65fc46be2f333.png'
    @url = Rails.configuration.app['web']['url'] + '/widget-tutorial'
    mail(to: recipient.emails.map(&:email), subject: "Did you know you can see your most recent snaps and stories in the notification center? Turn on your iOS 8 widget today")
  end
end
