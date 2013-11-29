class MonitorController < ActionController::Base
  #newrelic_ignore

  def health_check
    render text: 'Okay'
  end
end
