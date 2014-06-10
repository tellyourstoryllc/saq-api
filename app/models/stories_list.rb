class StoriesList
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::TwoUserConversation

  def save
    return unless valid?

    write_attrs
  end

  # Add the story to the list, but don't set the rank on the story itself,
  # since the rank can change depending on the list it's being viewed in
  def add_message(story)
    lua_script = %{local rank = redis.call('INCR', KEYS[1]); redis.call('ZADD', KEYS[2], rank, ARGV[1])}
    redis.eval lua_script, {keys: [rank.key, message_ids.key], argv: [story.id]}
  end


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't see that user's stories.") if blocked?
  end

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, created_at: created_at)
  end
end
