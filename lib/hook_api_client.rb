class HookApiClient
  include HTTParty
  base_uri 'https://api.hookmobile.com:8005/api'
  MAX_LENGTH = 140

  cattr_accessor :logger
  self.logger = ::Logger.new('/dev/null')


  def self.post_to(endpoint, body)
    response = post(endpoint, {body: body})
    res = JSON.load(response) rescue response
    logger.info("Hook API: POST to #{endpoint}. Request: #{body}. Response: #{res}")
    res
  end

  def self.send_sms(from, to, text, options = {})
    raise StandardError.new("Text must be <= #{MAX_LENGTH} characters.") if text.size > MAX_LENGTH
    post_to('/sendsms', options.merge(from: from, recipient: to, text: text))
  end
end
