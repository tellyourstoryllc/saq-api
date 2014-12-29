module Moderator
  extend self

  attr_reader :url, :callback_url, :token

  @url          = Rails.configuration.app['moderator'].try(:[], 'url')
  @callback_url = Rails.configuration.app['moderator'].try(:[], 'callback_url')
  @token        = Rails.configuration.app['moderator'].try(:[], 'token')

  # Fail fast if we're not configured.  In dev, we don't care.
  if ! %w[development test].include?(Rails.env)
    %w[url callback_url token].each do |key|
      raise "Moderator expected config key #{key}" if ! send(key)
    end
  end

end
