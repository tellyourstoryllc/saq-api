class BaseMailer < ActionMailer::Base
  default from: 'skymob <info@skymob.co>'

  def mail(options)
    super unless options[:to].blank?
  end
end
