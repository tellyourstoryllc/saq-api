class PasswordResetMailer < BaseMailer
  def reset(account, token)
    @url = reset_password_url(token)
    mail(to: account.email, subject: 'Password Reset Instructions')
  end
end
