class Feed
  include Peanut::Model
  include Redis::Objects

  attr_accessor :current_user
  attr_accessor :options

  USER_LIMIT = 500

  def self.results_expiration
    1.hour
  end

  def users_key
    @key ||= begin
      criteria = base_users_scope.to_sql
      "feed:user:#{current_user.id}:#{Digest::MD5.hexdigest(criteria)}:user_ids"
    end
  end

  def exists?
    users_key && redis.exists(users_key)
  end

  def options=(hsh)
    @options = hsh

    @options[:latitude] ||= current_user.latitude
    @options[:longitude] ||= current_user.longitude

    @options[:limit] = (@options[:limit] || 10).to_i
    @options[:limit] = 100 if @options[:limit] > 100

    @options[:offset] = @options[:offset].to_i
  end

  def base_users_scope
    o = options

    scope = User.select('users.id')
    scope = scope.where(deactivated: false)
    scope = scope.joins(:account).where(accounts: { registered: true })

    # TODO: bounding radius.

    # Sort.
    order_by = if o[:sort] == 'nearest' && o[:latitude] && o[:longitude]
      User.coordinate_order_options(o[:latitude], o[:longitude])
    else # newest
      # Use id so that it's stable.
      'users.created_at DESC, id'
    end
    scope = scope.reorder(order_by)

    scope = scope.limit(USER_LIMIT)

    scope
  end

  def results
    @results ||= begin
      start = options[:offset]
      stop = options[:offset] + options[:limit] - 1

      if exists?
        user_ids = redis.lrange(users_key, start, stop)

        user_ids
      else
        srand 3 if Rails.env.development? # For testing

        # Fetch potential feed items.
        user_ids = base_users_scope.to_a.map(&:id)

        return [] if user_ids.empty?

        redis.multi do
          if user_ids.present?
            redis.rpush(users_key, user_ids)
            redis.expire(users_key, self.class.results_expiration)
          end
        end

        user_ids_page = user_ids[start..stop] || []

        user_ids_page
      end
    end
  end

  def self.feed_api(current_user, options)
    return [] if current_user.blank?

    feed = new
    feed.current_user = current_user
    feed.options = options

    user_ids = feed.results

    user_ids.uniq!

    return [] if user_ids.blank?

    # Preserve order when fetching from the db.
    user_objects = User.where(id: user_ids).reorder("field(id, #{user_ids.map(&:inspect).join(',')})")

    user_objects
  end

end
