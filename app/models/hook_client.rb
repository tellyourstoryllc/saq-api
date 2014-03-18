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

    text = render_text_with_name(sender.name, " is trying to send you photos and videos on #{Rails.configuration.app['app_name']}: #{url}")
    send_sms(from, recipient_number, text)
  end

  def self.invite_to_group(sender, recipient, group, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"

    text = render_text_with_name(sender.name, " just sent you a message from #{Rails.configuration.app['app_name']}. See it here: #{url}")
    send_sms(from, recipient_number, text)
  end

  def self.invite_via_message(sender, recipient, message, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"
    media_type = message.message_attachment.try(:friendly_media_type) || 'a message'

    # expires_text = " that expires in #{distance_of_time_in_words(Time.current, Time.zone.at(message.expires_at))}" if message.expires_at
    # text = render_text_with_name(sender.name, " sent you #{media_type} on #{Rails.configuration.app['app_name']}#{expires_text}: #{url}")
    text = render_text_with_name(sender.name, " just sent you #{media_type} from #{Rails.configuration.app['app_name']}. See it here: #{url}")
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

  # Truncate sender name if needed to ensure our copy fits
  def self.render_text_with_name(sender_name, text)
    sender_name = sender_name.truncate(HookApiClient::MAX_LENGTH - (text.size + CANCEL_TEXT.size))
    render_text(sender_name + text)
  end

  # Truncate the content if needed to ensure the cancel text fits
  def self.render_text(text)
    text.truncate(MAX_CONTENT_LENGTH) + CANCEL_TEXT
  end
end
