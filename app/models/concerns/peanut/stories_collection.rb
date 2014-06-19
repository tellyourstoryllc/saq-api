module Peanut::StoriesCollection
  extend ActiveSupport::Concern

  # Add the story to the list only if it's not already there
  # And don't set the rank on the story itself,
  # since the rank can change depending on the list it's being viewed in
  def add_message(story)
    lua_script = %{if not redis.call('ZSCORE', KEYS[2], ARGV[1]) then local rank = redis.call('INCR', KEYS[1]); return redis.call('ZADD', KEYS[2], rank, ARGV[1]) end}
    redis.eval lua_script, {keys: [rank.key, message_ids.key], argv: [story.id]}
  end
end
