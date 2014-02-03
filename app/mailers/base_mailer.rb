class BaseMailer < ActionMailer::Base
  default from: 'skymob <info@skymob.co>'
  add_template_helper ApplicationHelper

  def mail(options)
    super unless options[:to].blank?
  end
end
