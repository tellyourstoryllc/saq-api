class HookClient
  CANCEL_TEXT = ' Reply NOOOO to cancel'
  MAX_CONTENT_LENGTH = HookApiClient::MAX_LENGTH - CANCEL_TEXT.size


  def self.invite_to_contacts(sender, recipient, recipient_number, invite_token)
    from = Rails.configuration.app['hook']['invite_from']
    url = Rails.configuration.app['web']['domain'] + "/i/#{invite_token}"
    text = render_text(sender.name, " wants to chat with you on the new app: #{url}")

    HookApiClient.send_sms(from, recipient_number, text)
  end


  private

  # Truncate sender name if needed to ensure our copy fits
  def self.render_text(sender_name, text)
    sender_name = sender_name.truncate(HookApiClient::MAX_LENGTH - (text.size + CANCEL_TEXT.size))
    sender_name + text + CANCEL_TEXT
  end
end
