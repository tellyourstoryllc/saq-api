class FayePublisher
  ENDPOINT = Rails.configuration.app['faye']['url']
  SECRET = Rails.configuration.app['faye']['server_secret']
  attr_accessor :token


  def initialize(token)
    self.token = token
  end

  def publish(channel, data = {}, ext = {})
    message = {
      channel: channel,
      data: data,
      ext: ext.merge(token: token, server_secret: SECRET)
    }

    HTTParty.post(ENDPOINT, body: {message: message.to_json})
  end

  def broadcast_to_contacts
    publish '/internal/broadcast_to_contacts'
  end

  def publish_to_group(group, data)
    publish "/groups/#{group.id}/messages", data, {persisted: true}
  end

  def publish_one_to_one_message(user, data)
    publish "/users/#{user.id}", data, {action: 'create_one_to_one_message', persisted: true}
  end

  def publish_group_to_user(user, data)
    publish "/users/#{user.id}", data, {action: 'updated_group'}
  end

  def publish_preferences(user, data)
    publish "/users/#{user.id}", data, {action: 'updated_preferences'}
  end
end
