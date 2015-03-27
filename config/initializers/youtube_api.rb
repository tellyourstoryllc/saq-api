config = Rails.configuration.app['youtube']

YOUTUBE_CLIENT = Google::APIClient.new
YOUTUBE_CLIENT.retries = 5
YOUTUBE_CLIENT.authorization.client_id = config['client_id']
YOUTUBE_CLIENT.authorization.client_secret = config['client_secret']
YOUTUBE_CLIENT.authorization.access_token = config['old_access_token']
YOUTUBE_CLIENT.authorization.refresh_token = config['refresh_token']

YOUTUBE_API = YOUTUBE_CLIENT.discovered_api('youtube', 'v3')
