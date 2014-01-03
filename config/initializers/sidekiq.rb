config = YAML.load_file(File.join(Rails.root, 'config', 'sidekiq.yml'))
shared_config = config.reject{ |k,v| %w(development test testing staging production).include?(k.to_s) }
merged_config = shared_config.merge(config.delete(Rails.env) || {})
Rails.configuration.app['sidekiq'] = {}
merged_config.each{ |k,v| Rails.configuration.app['sidekiq'][k.to_s] = v }

sidekiq_config = Rails.configuration.app['sidekiq']
namespace = 'sidekiq'

module Peanut
  module Sidekiq
    module Middleware
    end
  end
end

class Peanut::Sidekiq::Middleware::EnqueueStats
  def call(worker_class, msg, queue)
    worker_class = worker_class.constantize if worker_class.is_a?(String)
    worker_class.record_event(:enqueue, Rails.logger)
    yield
  end
end

Sidekiq.configure_server do |config|
  config.redis = {url: sidekiq_config['redis_url'], namespace: namespace, driver: 'hiredis'}

  config.client_middleware do |chain|
    chain.add Peanut::Sidekiq::Middleware::EnqueueStats
  end
end

# When in Unicorn, this block needs to go in unicorn's `after_fork` callback:
Sidekiq.configure_client do |config|
  config.redis = {url: sidekiq_config['redis_url'], namespace: namespace, driver: 'hiredis'}

  config.client_middleware do |chain|
    chain.add Peanut::Sidekiq::Middleware::EnqueueStats
  end
end
