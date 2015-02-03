class BaseMailer < ActionMailer::Base
  default from: "#{Rails.configuration.app['app_name_short']} <info@#{Rails.configuration.app['sendgrid']['domain']}>"
  include ActionView::Helpers::DateHelper
  add_template_helper ApplicationHelper
  BLACKLISTED_DOMAINS = /snap.io|ffm.fm|krazychat.com|krazykam.com/

  def mail(options)
    super unless invalid_to?(options[:to])
  end

  def invalid_to?(to)
    return true if to.blank?

    to = Array(to) if to.is_a?(String)
    to.reject!{ |e| e =~ BLACKLISTED_DOMAINS }
    to.blank?
  end
end
