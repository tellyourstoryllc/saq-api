class GroupMixpanelWorker < BaseWorker
  def self.category; :mixpanel end
  def self.metric; :group_track end

  def perform(event_name, properties = {}, options = {})
    perform_with_tracking(event_name, properties, options) do
      GroupMixpanelClient.new.track!(event_name, properties, options)
    end
  end

  statsd_measure :perform, metric_prefix
end
