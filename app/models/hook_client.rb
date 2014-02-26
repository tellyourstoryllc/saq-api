class HookClient
  include Redis::Objects

  hash_key :daily_sent_sms_counts, global: true
  hash_key :monthly_sent_sms_counts, global: true
  counter :all_time_sent_sms_count, global: true

  hash_key :daily_received_sms_counts, global: true
  hash_key :monthly_received_sms_counts, global: true
  counter :all_time_received_sms_count, global: true

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
    text = render_text_with_name(sender.name, " wants to chat with you on the new app: #{url}")

    send_sms(from, recipient_number, text)
  end

  def self.invite_to_group(sender, recipient, group, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['url'] + "/i/#{invite_token}"

    text = render_text_with_name(sender.name, " sent you a message on krazychat. Click here to view it: #{url}")

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

  def self.increment_received_sms_counts
    today = Time.zone.today

    redis.multi do
      redis.hincrby(daily_received_sms_counts.key, today.to_s, 1)
      redis.hincrby(monthly_received_sms_counts.key, today.strftime('%Y-%m'), 1)
      redis.incr(all_time_received_sms_count.key)
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
