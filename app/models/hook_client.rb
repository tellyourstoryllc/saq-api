class HookClient
  include Redis::Objects

  hash_key :sent_sms_counts, global: true
  hash_key :received_sms_counts, global: true

  CANCEL_TEXT = ' Reply NOOOO to cancel'
  MAX_CONTENT_LENGTH = HookApiClient::MAX_LENGTH - CANCEL_TEXT.size


  def self.send_sms(from, recipient_number, text)
    # Silently throw away the SMS if the recipient has unsubscribed
    return if Phone.get(recipient_number).try(:unsubscribed?)

    increment_sent_sms_counts
    HookApiClient.send_sms(from, recipient_number, text)
  end

  def self.invite_to_contacts(sender, recipient, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['domain'] + "/i/#{invite_token}"
    text = render_text_with_name(sender.name, " wants to chat with you on the new app: #{url}")

    send_sms(from, recipient_number, text)
  end

  def self.invite_to_group(sender, recipient, group, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['domain'] + "/i/#{invite_token}"
    text = render_text_with_name(sender.name, " added you to the room \"#{group.name.truncate(30)}\" on the new app: #{url}")

    send_sms(from, recipient_number, text)
  end

  def self.increment_sent_sms_counts
    sent_sms_counts.incrby(Time.zone.today.to_s)
  end

  def self.increment_received_sms_counts
    received_sms_counts.incrby(Time.zone.today.to_s)
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
