class HookController < ApplicationController
  skip_before_action :require_token
  before_action :restrict_domain, :validate_body


  def callback
    case parsed_body['type']
    when 'incomingSms'
      handle_incoming_sms
    end

    render_success
  end


  private

  def restrict_domain
    return unless Rails.env.production?

    domain = Resolv.getname(request.remote_ip) rescue ''
    raise "Hook callback attempt from non-Hook domain!" unless domain.ends_with?('hookmobile.com')
  end

  def validate_body
    raise 'Invalid parsed body.' unless parsed_body.present? && parsed_body['type']
  end

  def parsed_body
    @parsed_body ||= JSON.load(request.raw_post) rescue nil
  end

  def from_phone
    @from_phone ||= Phone.get(parsed_body['from'])
  end

  def handle_incoming_sms
    IncomingText.create!(raw_body: request.raw_post, from: parsed_body['from'],
                         recipient: parsed_body['recipient'], text: parsed_body['text'],
                         message_id: parsed_body['messageId'], timestamp: parsed_body['timestamp'])

    case parsed_body['text'].strip
    when /^(NO+|STOP|UNSUBSCRIBE|CANCEL)$/i
      from_phone.update!(unsubscribed: true)
    when /^(YES+|START|SUBSCRIBE)$/i
      from_phone.update!(unsubscribed: false)
    end
  end
end
