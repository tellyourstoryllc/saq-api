class AdminController < ActionController::Base
  http_basic_authenticate_with name: Rails.configuration.app['admin']['username'], password: Rails.configuration.app['admin']['password']

  def sms_stats
    @today = Time.zone.today

    @daily_sent_sms_counts = HookClient.daily_sent_sms_counts.all
    @monthly_sent_sms_counts = HookClient.monthly_sent_sms_counts.all
    @all_time_sent_sms_count = HookClient.all_time_sent_sms_count.get

    @daily_received_sms_counts = HookClient.daily_received_sms_counts.all
    @monthly_received_sms_counts = HookClient.monthly_received_sms_counts.all
    @all_time_received_sms_count = HookClient.all_time_received_sms_count.get

    @daily_error_counts = HookClient.daily_error_counts.all
    @monthly_error_counts = HookClient.monthly_error_counts.all
    @all_time_error_count = HookClient.all_time_error_count.get
  end

  def cohort_metrics
    @today = Time.zone.today
    @days = 14

    @sent_raw = {}
    @received_raw = {}
    @sent = {}
    @received = {}

    User.redis.pipelined do
      @days.times do |i|
        registered_date = (@today - i).to_s
        key = User.cohort_metrics_key(registered_date)
        @sent_raw[registered_date] = User.redis.hgetall(key)
        @received_raw[registered_date] = User.redis.hgetall(key)
      end
    end

    @days.times do |i|
      registered_date = (@today - i).to_s
      sent_metrics = @sent_raw[registered_date].value
      received_metrics = @received_raw[registered_date].value

      registered_key = "registered_on_#{registered_date}"
      @sent[registered_key] = {}
      @received[registered_key] = {}

      @days.times do |j|
        action_date = (@today - j).to_s

        reg = sent_metrics["sent_to_registered_#{action_date}"].to_f
        unreg = sent_metrics["sent_to_unregistered_#{action_date}"].to_f
        @sent[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0

        reg = received_metrics["received_from_registered_#{action_date}"].to_f
        unreg = received_metrics["received_from_unregistered_#{action_date}"].to_f
        @received[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0
      end
    end
  end
end
