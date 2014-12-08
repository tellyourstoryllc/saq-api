class Redis
  class Client
    protected
    def logging(commands) # Overwrite redis-rb logger
      # Determin if Log every thing by Rails.logger because ActiveRecord Callback can't use @logger
      return yield unless Rails.logger.debug?

      queries = commands.map do |name, *args|
        line = "#{name.to_s.upcase} #{args.map(&:to_s).join(" ")}"
        #line << "\n#{caller.grep(/\/app\//).first(4).map{ |line| '    ' + line }.join("\n")}" if Rails.env.development?
        line
      end

      ::ActiveSupport::Notifications.instrument('query.redis_logger', :query => queries.join(' | ')) do
        @exec_result = yield
      end

      @exec_result
    end
  end
end
