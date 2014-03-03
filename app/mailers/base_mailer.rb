class BaseMailer < ActionMailer::Base
  default from: 'krazychat <info@krazychat.com>'
  include ActionView::Helpers::DateHelper
  add_template_helper ApplicationHelper

  def mail(options)
    super unless options[:to].blank?
  end
end
