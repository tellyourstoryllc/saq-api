class FacebookProfileWorker < BaseWorker
  def self.category; :facebook end
  def self.metric; :profile end

  def perform(facebook_id)
    perform_with_tracking(facebook_id) do
      begin
        facebook_user = FacebookUser.new(id: facebook_id)
        facebook_user.fetch_profile!
        true
      rescue Koala::Facebook::APIError => e
        # Fail silently if the user has since
        # uninstalled the FB app
        e.message.include?('Unsupported operation') ? true : raise
      end
    end
  end

  statsd_measure :perform, metric_prefix
end
