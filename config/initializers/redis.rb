persisted = Rails.configuration.app['redis']['persisted']
redis = Redis.new(host: persisted['host'], db: persisted['db'])
Redis.current = Redis::Namespace.new("chat_app_#{Rails.env}", redis: redis)
