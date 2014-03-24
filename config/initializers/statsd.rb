statsd = Rails.configuration.app['statsd']

StatsD.server = statsd['server']
StatsD.logger = Rails.logger
StatsD.mode = :production

prefix = Rails.configuration.app['statsd']['prefix']
prefix << "_#{Rails.env}" unless Rails.env.production?
StatsD.prefix = prefix
