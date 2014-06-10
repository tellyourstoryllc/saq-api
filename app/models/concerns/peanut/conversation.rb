module Peanut::Conversation
  extend ActiveSupport::Concern
  attr_accessor :viewer


  included do
    hash_key :attrs
    counter :rank
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
    below_message_id = options[:below_message_id]

    below_rank = if below_rank.present?
                   below_rank.to_i
                 elsif below_message_id.present?
                   message_ids[below_message_id]
                 end

    return [] if below_rank && below_rank <= 0

    max = below_rank ? below_rank - 1 : 'inf'
    deleted_rank = last_deleted_rank
    min = deleted_rank ? deleted_rank + 1 : '-inf'

    ids = message_ids.revrangebyscore(max, min, {limit: limit}).reverse
    Message.pipelined_find(ids)
  end

  # Find all expired message ids and remove them from the sorted set
  def remove_expired_message_ids
    lua_script = %{local message_ids = redis.call("ZRANGEBYSCORE", KEYS[1], '-inf', ARGV[1]); for k,v in pairs(message_ids) do redis.call("ZREM", KEYS[1], v); redis.call("ZREM", KEYS[2], v) end}
    redis.eval lua_script, {keys: [message_id_expirations.key, message_ids_without_expiration_gc.key], argv: [Time.current.to_i]}
  end

  def last_message_at
    @last_message_at ||= Message.redis.hget("message:#{message_ids.last}:attrs", :created_at)
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

  def last_seen_rank=(seen_rank)
    return if viewer.nil?

    old_last_seen_rank = last_seen_rank
    redis.hset(metadata_key, :last_seen_rank, seen_rank)

    viewed_message_ids = message_ids.rangebyscore(last_seen_rank.to_i + 1, seen_rank)
    viewer.unviewed_message_ids.delete(viewed_message_ids) if viewed_message_ids.present?
    User.check_unviewed_message_ids(viewer)
  end

  def last_deleted_rank
    data = metadata
    data['last_deleted_rank'].try(:to_i) if data
  end

  def last_deleted_rank=(rank)
    redis.hset(metadata_key, :last_deleted_rank, rank) if viewer
  end

  def hidden
    data = metadata
    self.class.to_bool(data['hidden']) || false if data
  end

  def hidden=(value)
    redis.hset(metadata_key, :hidden, value) if viewer
  end
end
