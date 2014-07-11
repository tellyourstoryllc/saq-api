# Load the Rails environment
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'environment'))

#sleep_time = 10
sleep_time = 120

started_template = "\n[%s] Started content-available enqueuing."
ended_template = "[%s] (%s sec) Ended content-available enqueuing."


loop do
  start_time = Time.current
  started_text = started_template % start_time.to_s(:db)
  puts started_text
  Rails.logger.info started_text

  ContentNotifier.new.send_notifications

  end_time = Time.current
  ended_text = ended_template % [end_time.to_s(:db), (end_time - start_time).round]
  puts ended_text
  Rails.logger.info ended_text

  sleep sleep_time
end
