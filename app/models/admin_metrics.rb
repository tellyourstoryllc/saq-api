class AdminMetrics
  DAYS = 14
  HOURS_CACHED = 1

  def cache_key
    'user::metrics:cohort:average_percentage_registered'
  end

  def cache
    @cache ||= User.redis.hgetall(cache_key)
  end

  def today
    @today ||= Time.zone.today
  end

  def in_progress?
    User.redis.hget(cache_key, :started_at).present?
  end

  def next_recalculation_at
    Time.zone.at(cache['timestamp'].to_i) + HOURS_CACHED.hours
  end

  def stale?
    cache['timestamp'].blank? || Time.current >= next_recalculation_at
  end

  def fetch_friend_metrics
    metrics = JSON.load(cache['data'] || '{}')

    # If the current cache is stale and the cache isn't currently
    # being calculated, calculate it
    if stale? && !in_progress?
      if Settings.enabled?(:queue)
        User.redis.hset(cache_key, :started_at, Time.current.to_i)
        AdminFriendsPercentageWorker.perform_async
      else
        metrics = fetch_friend_metrics!
      end
    end

    metrics
  end

  def fetch_friend_metrics!
    User.redis.hset(cache_key, :started_at, Time.current.to_i)
    metrics = {}

    DAYS.times do |i|
      registered_date = today - i
      registered_from = Time.zone.local_to_utc(registered_date.to_datetime).to_s(:db)
      registered_to = Time.zone.local_to_utc((registered_date + 1).to_datetime - 1.second).to_s(:db)
      metrics[registered_date.to_s] = {}

      User.joins(:account).where('accounts.registered_at BETWEEN ? AND ?', registered_from, registered_to).find_each do |u|
        # Exclude yourself and the bot
        friend_ids = u.snapchat_friend_ids.members - [u.id, Robot.user.id]
        friends_count = friend_ids.size
        friends = User.includes(:account).where(id: friend_ids).to_a

        DAYS.times do |j|
          action_date = (today - j)
          next if action_date < registered_date || !u.active_on?(action_date)

          metrics[registered_date.to_s][action_date.to_s] ||= {}
          metrics[registered_date.to_s][action_date.to_s][u.id] ||= {}

          registered_count = friends.count{ |c| c.account.registered_at.present? && c.account.registered_at.to_date <= action_date }
          metrics[registered_date.to_s][action_date.to_s][u.id]['friends_counts'] = friends_count
          metrics[registered_date.to_s][action_date.to_s][u.id]['registered_counts'] = registered_count
          metrics[registered_date.to_s][action_date.to_s][u.id]['percent_registered'] = (registered_count.to_f / friends_count) * 100 if friends_count > 0
        end
      end
    end

    User.redis.hmset(cache_key, :timestamp, Time.current.to_i, :started_at, nil, :data, metrics.to_json)

    metrics
  end

  def fetch_message_metrics
    raw = {}
    sent = {}
    received = {}

    User.redis.pipelined do
      DAYS.times do |i|
        registered_date = (today - i).to_s
        key = User.cohort_metrics_key(registered_date)
        raw[registered_date] = User.redis.hgetall(key)
      end
    end

    DAYS.times do |i|
      registered_date = (today - i).to_s
      metrics = raw[registered_date].value

      registered_key = "registered_on_#{registered_date}"
      sent[registered_key] = {}
      received[registered_key] = {}

      DAYS.times do |j|
        action_date = (today - j).to_s

        reg = metrics["sent_to_registered_#{action_date}"].to_f
        unreg = metrics["sent_to_unregistered_#{action_date}"].to_f
        sent[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0 || unreg > 0

        reg = metrics["received_from_registered_#{action_date}"].to_f
        unreg = metrics["received_from_unregistered_#{action_date}"].to_f
        received[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0 || unreg > 0
      end
    end

    return sent, received
  end
end
