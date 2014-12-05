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

    # Skip publishing when developing and the local Faye server isn't up
    HTTParty.post(ENDPOINT, body: {message: message.to_json}) unless (Rails.env.development? || Rails.env.test?) && HTTParty.head(FayePublisher::ENDPOINT) rescue nil
  end

  def broadcast_to_contacts
    publish '/internal/broadcast_to_contacts'
  end

  def broadcast_to_followers
    publish '/internal/broadcast_to_followers'
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

  def publish_one_to_one_to_user(user, data)
    publish "/users/#{user.id}", data, {action: 'updated_one_to_one'}
  end

  def publish_preferences(user, data)
    publish "/users/#{user.id}", data, {action: 'updated_preferences'}
  end

  def broadcast_account_to_one_to_one_users(user, data)
    publish '/internal/broadcast_account_to_one_to_one_users', data
  end
end
