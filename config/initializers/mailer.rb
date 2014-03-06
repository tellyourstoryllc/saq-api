sendgrid_config = Rails.configuration.app['sendgrid']

if sendgrid_config and sendgrid_config['username'] and sendgrid_config['password']
  KrazyChat::Application.config.action_mailer.smtp_settings = {
    :address              => 'smtp.sendgrid.net',
    :port                 => 587,
    :domain               => Rails.configuration.app['sendgrid']['domain'],
    :user_name            => sendgrid_config['username'],
    :password             => sendgrid_config['password'],
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }

  KrazyChat::Application.config.action_mailer.default_url_options = {host: Rails.configuration.app['web']['domain']}
end
