class Story < Message
  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end


  private

  # Atomically set the rank and add it to the conversation's message list
  def add_to_conversation
    convo = conversation
    return if convo.nil?

    # Add the story to the list, but don't set the rank on the story itself,
    # since the rank can change depending on the list it's being viewed in
    lua_script = %{local rank = redis.call('INCR', KEYS[1]); redis.call('ZADD', KEYS[2], rank, ARGV[1])}
    redis.eval lua_script, {keys: [convo.rank.key, convo.message_ids.key], argv: [id]}
  end
end
