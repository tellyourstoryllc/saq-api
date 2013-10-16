persisted = Rails.configuration.app['redis']['persisted']
Redis.current = Redis.new(host: persisted['host'], port: persisted['port'], db: persisted['db'], logger: Rails.logger)
