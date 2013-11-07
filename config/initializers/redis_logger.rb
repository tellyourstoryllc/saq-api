class Redis
  class Client
    protected
    def logging(commands) # Overwrite redis-rb logger
      # Determin if Log every thing by Rails.logger because ActiveRecord Callback can't use @logger
      return yield unless Rails.logger.debug?

      queries = commands.map do |name, *args|
        "#{name.to_s.upcase} #{args.map(&:to_s).join(" ")}"
      end

      ::ActiveSupport::Notifications.instrument('query.redis_logger', :query => queries.join(' | ')) do
        @exec_result = yield
      end

      @exec_result
    end
  end
end
