class HookController < ApplicationController
  skip_before_action :require_token
  before_action :restrict_domain, :increment_stats, :validate_body


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

  def mixpanel
    @mixpanel ||= MixpanelClient.new(user)
  end

  def increment_stats
    HookClient.increment_received_sms_counts
  end

  def validate_body
    raise 'Invalid parsed body.' unless parsed_body.present? && parsed_body['type']
  end

  def parsed_body
    @parsed_body ||= JSON.load(request.raw_post) rescue {}
  end

  def content
    @content ||= parsed_body['text'].strip
  end

  def from_phone
    return @from_phone if defined?(@from_phone)

    number = Phone.normalize(parsed_body['from'])
    @from_phone = Phone.find_or_create_by(number: number) if number
    @from_phone.user = user if @from_phone && user
    @from_phone
  end

  def user
    return @user if defined?(@user)

    content =~ /: (\w+)$/
    user_id = User.user_ids_by_phone_verification_token[$1] if $1
    @user = User.find_by(id: user_id) if user_id
  end

  def handle_incoming_sms
    IncomingText.create!(raw_body: request.raw_post, from: parsed_body['from'],
                         recipient: parsed_body['recipient'], text: parsed_body['text'],
                         message_id: parsed_body['messageId'], timestamp: parsed_body['timestamp'])

    return if from_phone.nil?

    case content
    when /^(NO+|STOP|UNSUBSCRIBE|CANCEL)$/i
      from_phone.unsubscribed = true
    when /^(YES+|START|SUBSCRIBE)$/i
      from_phone.unsubscribed = false
    end

    from_phone.verified = true
    from_phone.save!

    mixpanel.verified_phone(from_phone)
  end
end
