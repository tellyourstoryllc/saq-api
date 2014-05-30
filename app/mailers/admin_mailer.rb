class AdminMailer < BaseMailer
  def password_reset(sysop)
    @url = admin_reset_password_url(host: Rails.configuration.app['api']['url'], admin_token: sysop.token)
    @name = sysop.name
    mail(to: sysop.email, subject: 'Admin Password Reset Instructions')
  end
end
