class AdminFriendsPercentageWorker < BaseWorker
  def self.category; :admin end
  def self.metric; :friends_percentage end

  def perform
    perform_with_tracking do
      AdminMetrics.new.fetch_friend_metrics!
    end
  end

  statsd_measure :perform, metric_prefix
end
