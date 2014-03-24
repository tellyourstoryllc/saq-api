statsd = Rails.configuration.app['statsd']

StatsD.server = statsd['server']
StatsD.logger = Rails.logger
StatsD.mode = :production

prefix = Rails.configuration.app['app_name'].dup.split(' ').map(&:underscore).join('_')
prefix << "_#{Rails.env}" unless Rails.env.production?
StatsD.prefix = prefix
