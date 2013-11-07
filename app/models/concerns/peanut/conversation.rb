module Peanut::Conversation
  extend ActiveSupport::Concern

  included do
    # These can be overridden
    def self.page_size; 20 end
    def self.max_page_size; 200 end
  end

  def paginate_messages(options = {})
    limit = [(options[:limit].presence || self.class.page_size).to_i, self.class.max_page_size].min
    return [] if limit == 0

    last_message_id = options[:last_message_id]

    ids = if last_message_id.present?
      message_ids.revrangebyscore("(#{last_message_id}", '-inf', {limit: limit}).reverse
    else
      message_ids.range(-limit, -1)
    end

    ids.map{ |id| Message.new(id: id) }
  end
end
