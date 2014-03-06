class BaseMailer < ActionMailer::Base
  default from: "#{Rails.configuration.app['app_name']} <info@#{Rails.configuration.app['sendgrid']['domain']}>"
  add_template_helper ApplicationHelper

  def mail(options)
    super unless options[:to].blank?
  end
end
