module Peanut::Conversation
  extend ActiveSupport::Concern
  attr_accessor :viewer


  included do
    sorted_set :message_ids
    sorted_set :message_id_expirations

    # These can be overridden
    def self.page_size; 20 end
    def self.max_page_size; 200 end

    def message_ids_with_expiration_gc
      remove_expired_message_ids
      message_ids_without_expiration_gc
    end
    alias_method_chain :message_ids, :expiration_gc
  end

  def paginate_messages(options = {})
    limit = [(options[:limit].presence || self.class.page_size).to_i, self.class.max_page_size].min
    return [] if limit == 0

    below_rank = options[:below_rank]
    below_rank = below_rank.to_i if below_rank.present?
    return [] if below_rank && below_rank <= 0

    ids = if below_rank
      message_ids.range([below_rank - limit, 0].max, below_rank - 1)
    else
      message_ids.range(-limit, -1)
    end

    Message.pipelined_find(ids)
  end

  # Find all expired message ids and remove them from the sorted set
  def remove_expired_message_ids
    lua_script = %{local message_ids = redis.call("ZRANGEBYSCORE", KEYS[1], '-inf', ARGV[1]); for k,v in pairs(message_ids) do redis.call("ZREM", KEYS[1], v); redis.call("ZREM", KEYS[2], v) end}
    redis.eval lua_script, {keys: [message_id_expirations.key, message_ids_without_expiration_gc.key], argv: [Time.current.to_i]}
  end

  def last_message_at
    @last_message_at ||= message_ids.range(-1, -1, with_scores: true).first.try(:last).try(:round)
  end

  def metadata_key
    "#{self.class.to_s.underscore}:#{id}:viewer_metadata:#{viewer.id}" if viewer
  end

  def metadata
    @metadata ||= redis.hgetall(metadata_key) if viewer
  end

  def last_seen_rank
    data = metadata
    data['last_seen_rank'].try(:to_i) if data
  end

  def last_seen_rank=(rank)
    redis.hset(metadata_key, :last_seen_rank, rank) if viewer
  end

  def hidden
    data = metadata
    self.class.to_bool(data['hidden']) || false if data
  end

  def hidden=(value)
    redis.hset(metadata_key, :hidden, value) if viewer
  end
end
