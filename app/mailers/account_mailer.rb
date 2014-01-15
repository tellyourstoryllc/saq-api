class AccountMailer < BaseMailer
  def welcome(account)
    mail(to: account.emails.map(&:email), subject: 'Welcome to skymob')
  end

  def password_reset(account, token)
    @url = reset_password_url(token)
    mail(to: account.emails.map(&:email), subject: 'Password Reset Instructions')
  end
end
