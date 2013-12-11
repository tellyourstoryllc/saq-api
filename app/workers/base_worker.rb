class BaseWorker
  include Sidekiq::Worker
  extend StatsD::Instrument

  sidekiq_options queue: :default, retry: true, backtrace: 10


  # The child class' perform method should return false or nil (or raise an exception)
  # if the job failed, and anything else if it passed
  #
  # The job is retried automatically if it raises an exception, but not if it simply
  # return false or nil
  #
  # If the job failed, either by returning false or nil or by raising an exception,
  # we track that stat as a failure.  Otherwise it's tracked as a success.
  def perform_with_tracking(*args)
    self.class.record_event(:dequeue)
    Rails.logger.debug "Sidekiq perform: #{self} #{args} at #{Time.now}"

    success = yield
    self.class.record_event(success ? :success : :failure)
  rescue
    self.class.record_event(:failure)
    raise
  end

  # Implement in child class
  def self.category; end
  def self.metric; end

  def self.category_prefix
    return if category.nil?
    "queue.#{category}"
  end

  def self.metric_prefix
    return if category_prefix.nil? || metric.nil?
    "#{category_prefix}.#{metric}"
  end

  def self.record_event(event, logger = Sidekiq.logger)
    record_data_point("#{metric_prefix}.#{event}", logger) unless metric_prefix.nil?
  end

  def self.record_data_point(stat_name, logger = Sidekiq.logger)
    logger.debug "Job: recording #{stat_name} ... "
    StatsD.increment(stat_name)
    logger.debug 'done.'
  end
end
