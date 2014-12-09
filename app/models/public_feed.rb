class PublicFeed
  include Peanut::Model
  include Redis::Objects

  attr_accessor :current_user, :user_ids, :expanded_radius
  attr_reader :options

  MALE_PERCENTAGE = 0.5
  FEMALE_PERCENTAGE = 0.5
  USER_LIMIT = 500
  RADII = [25, 50, 100, :any]

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
    @options[:radius] = @options[:radius].present? ? @options[:radius].to_i : nil

    @options[:limit] = (@options[:limit] || 10).to_i
    @options[:limit] = 100 if @options[:limit] > 100

    @options[:offset] = @options[:offset].to_i
  end

  def bound_by_location?
    current_radius && options[:sort] != 'nearest'
  end

  def current_radius
    radius = expanded_radius || options[:radius]
    radius = false if expanded_radius && expanded_radius == :any
    radius
  end

  def base_users_scope
    o = options

    scope = User.select('users.id')
    scope = scope.where(deactivated: false)
    scope = scope.where('users.last_public_story_created_at IS NOT NULL')
    scope = scope.joins(:account).where(accounts: { registered: true })
    scope = scope.near([o[:latitude], o[:longitude]], current_radius, { select: '1', bearing: false }) if bound_by_location?

    # Sort.
    order_by = if o[:sort] == 'nearest' && o[:latitude] && o[:longitude]
      User.coordinate_order_options(o[:latitude], o[:longitude])
    else # newest
      # Use id so that it's stable.
      'users.created_at DESC, users.id'
    end
    scope = scope.reorder(order_by)

    scope = scope.limit(USER_LIMIT)

    scope
  end

  def male_users_scope
    base_users_scope.where(gender: 'male')
  end

  def female_users_scope
    base_users_scope.where(gender: 'female')
  end

  def results
    @results ||= begin
      start = options[:offset]
      stop = options[:offset] + options[:limit] - 1

      if exists?
        self.user_ids = redis.lrange(users_key, start, stop)

        user_ids
      else
        srand 3 if Rails.env.development? # For testing

        # Fetch potential feed items.
        self.user_ids = fetch_user_ids

        if bound_by_location?
          RADII.each do |radius|
            break if user_ids.present?
            next if radius.is_a?(Fixnum) && radius <= current_radius

            self.expanded_radius = radius
            self.user_ids = fetch_user_ids
          end
        end

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

  def fetch_user_ids
    populate_list(male_users_scope.pluck(:id), female_users_scope.pluck(:id))
  end

  # Populate user_ids until the desired ratio can no longer be maintained.
  def populate_list(male_user_ids, female_user_ids)
    male_limit = MALE_PERCENTAGE
    female_limit = FEMALE_PERCENTAGE
    user_ids = []

    while ! female_user_ids.empty?
      # Decide which list to pop a user_id from.
      rand_perc = rand
      Rails.logger.debug rand_perc
      chosen_user_ids = case rand_perc
                        when 0...female_limit then female_user_ids
                        when male_limit...100.0 then male_user_ids
                        end

      next if chosen_user_ids.empty?

      # Pop the next user_id.
      user_id = chosen_user_ids.shift
      user_ids << user_id
    end

    user_ids
  end

  def self.paginate_feed(current_user, options)
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
