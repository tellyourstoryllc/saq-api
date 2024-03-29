module ApplicationHelper
  def email_quote(user, message)
    "#{user.public_username || 'Somebody'}:#{' ' + message.text if message.text.present?}#{' (file attached)' if message.attachment_url.present?} | #{Time.zone.at(message.created_at).strftime('%-I:%M %p %Z')}"
  end
end
