class AccountMailer < BaseMailer
  def welcome(account)
    mail(to: account.emails.map(&:email), subject: "Welcome to #{Rails.configuration.app['app_name']}")
  end

  def password_reset(account, token)
    @url = reset_password_url(token)
    mail(to: account.emails.map(&:email), subject: 'Password Reset Instructions')
  end

  def missing_password(account, token)
    @url = reset_password_url(token)
    mail(to: account.emails.map(&:email), subject: 'Set Your Password')
  end
end
