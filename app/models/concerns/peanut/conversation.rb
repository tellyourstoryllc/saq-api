module Peanut::Conversation
  extend ActiveSupport::Concern

  included do
    sorted_set :message_ids
    counter :messages_count

    # These can be overridden
    def self.page_size; 20 end
    def self.max_page_size; 200 end
  end

  def paginate_messages(options = {})
    limit = [(options[:limit].presence || self.class.page_size).to_i, self.class.max_page_size].min
    return [] if limit == 0

    below_rank = options[:below_rank]

    ids = if below_rank.present?
      below_rank = below_rank.to_i
      message_ids.range([below_rank - limit, 0].max, below_rank - 1)
    else
      message_ids.range(-limit, -1)
    end

    Message.pipelined_find(ids)
  end
end
