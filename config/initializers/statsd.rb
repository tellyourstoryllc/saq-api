statsd = Rails.configuration.app['statsd']

StatsD.server = statsd['server']
StatsD.logger = Rails.logger
StatsD.mode = :production

prefix = 'krazychat'
prefix << "_#{Rails.env}" unless Rails.env.production?
StatsD.prefix = prefix
