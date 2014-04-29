class HookClient
  include Redis::Objects
  extend ActionView::Helpers::DateHelper

  hash_key :daily_sent_sms_counts, global: true
  hash_key :monthly_sent_sms_counts, global: true
  counter :all_time_sent_sms_count, global: true

  hash_key :daily_received_sms_counts, global: true
  hash_key :monthly_received_sms_counts, global: true
  counter :all_time_received_sms_count, global: true

  hash_key :daily_error_counts, global: true
  hash_key :monthly_error_counts, global: true
  counter :all_time_error_count, global: true

  CANCEL_TEXT = ''
  MAX_CONTENT_LENGTH = HookApiClient::MAX_LENGTH - CANCEL_TEXT.size


  def self.send_sms(from, recipient_number, text)
    # Silently throw away the SMS if the recipient has unsubscribed
    return if Phone.get(recipient_number).try(:unsubscribed?)

    increment_sent_sms_counts
    HookApiClient.send_sms(from, recipient_number, text)
  end

  def self.invite_to_contacts(sender, recipient, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"
    sender_phone = sender_phone_text(sender)

    text = render_from_template(ServerConfiguration.get('sms_invite_to_contacts'), {sender_name: sender.name, url: url, sender_phone: sender_phone})
    send_sms(from, recipient_number, text)
  end

  def self.invite_to_group(sender, recipient, group, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"
    sender_phone = sender_phone_text(sender)

    text = render_from_template(ServerConfiguration.get('sms_invite_to_group'), {sender_name: sender.name, url: url, sender_phone: sender_phone})
    send_sms(from, recipient_number, text)
  end

  def self.invite_via_message(sender, recipient, message, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"
    media_type = message.message_attachment.try(:friendly_media_type) || 'a message'
    sender_phone = sender_phone_text(sender)

    # expires_text = " that expires in #{distance_of_time_in_words(Time.current, Time.zone.at(message.expires_at))}" if message.expires_at
    text = render_from_template(ServerConfiguration.get('sms_invite_via_message'), {sender_name: sender.name, url: url, media_type: media_type, sender_phone: sender_phone})
    send_sms(from, recipient_number, text)
  end

  def self.send_verification(recipient_number, verification_code)
    from = Rails.configuration.app['hook']['invite_from']

    text = render_text("Your #{Rails.configuration.app['app_name']} code is: #{verification_code}.")
    send_sms(from, recipient_number, text)
  end

  def self.increment_sent_sms_counts
    today = Time.zone.today

    redis.multi do
      redis.hincrby(daily_sent_sms_counts.key, today.to_s, 1)
      redis.hincrby(monthly_sent_sms_counts.key, today.strftime('%Y-%m'), 1)
      redis.incr(all_time_sent_sms_count.key)
    end
  end

  def self.increment_received_sms_counts(error = false)
    today = Time.zone.today

    daily_key = error ? daily_error_counts.key : daily_received_sms_counts.key
    monthly_key = error ? monthly_error_counts.key : monthly_received_sms_counts.key
    all_time_key = error ? all_time_error_count.key : all_time_received_sms_count.key

    redis.multi do
      redis.hincrby(daily_key, today.to_s, 1)
      redis.hincrby(monthly_key, today.strftime('%Y-%m'), 1)
      redis.incr(all_time_key)
    end
  end


  private

  # Replace placeholder variables and if needed,
  # truncate sender name to ensure our copy fits
  def self.render_from_template(text, replacements = {})
    replacements.reverse_merge!(app_name: Rails.configuration.app['app_name'])
    replacements.each do |placeholder, value|
      text.gsub!("%#{placeholder}%", value.to_s) unless placeholder == :sender_name
    end

    sender_name = replacements[:sender_name]
    if sender_name
      name_placeholder = '%sender_name%'
      placeholder_size = text.include?(name_placeholder) ? name_placeholder.size : 0
      sender_name = sender_name.truncate(HookApiClient::MAX_LENGTH - (text.size - placeholder_size + CANCEL_TEXT.size))
      text.gsub!(name_placeholder, sender_name)
    end

    render_text(text)
  end

  # Truncate the content if needed to ensure the cancel text fits
  def self.render_text(text)
    text.truncate(MAX_CONTENT_LENGTH) + CANCEL_TEXT
  end

  def self.sender_phone_text(sender)
    sender_phone = sender.phones.last.try(:pretty)
    sender_phone.present? ? ' (' + sender_phone + ')' : ''
  end
end
