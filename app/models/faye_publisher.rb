class FayePublisher
  ENDPOINT = URI.parse(Rails.configuration.app['faye']['url'])
  attr_accessor :token


  def initialize(token)
    self.token = token
  end

  def publish(channel, data = {}, ext = {})
    message = {
      channel: channel,
      data: data,
      ext: ext.merge(token: token)
    }

    Net::HTTP.post_form(ENDPOINT, message: message.to_json)
  end

  def publish_to_group(group, data)
    publish "/groups/#{group.id}/messages", data, {persisted: true}
  end

  def publish_one_to_one_message(user, data)
    publish "/users/#{user.id}", data, {action: 'create_one_to_one_message', persisted: true}
  end

  def broadcast_to_contacts
    publish '/internal/broadcast_to_contacts'
  end
end
