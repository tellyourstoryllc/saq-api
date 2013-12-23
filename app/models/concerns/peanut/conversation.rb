module Peanut::Conversation
  extend ActiveSupport::Concern
  attr_accessor :viewer


  included do
    sorted_set :message_ids

    # These can be overridden
    def self.page_size; 20 end
    def self.max_page_size; 200 end
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
