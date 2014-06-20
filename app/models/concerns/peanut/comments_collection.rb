module Peanut::CommentsCollection
  extend ActiveSupport::Concern


  included do
    counter :comments_rank
    sorted_set :comment_ids

    # These can be overridden
    def self.page_size; 20 end
    def self.max_page_size; 200 end
  end

  def add_message(comment)
    lua_script = %{local rank = redis.call('INCR', KEYS[1]); return redis.call('ZADD', KEYS[2], rank, ARGV[1])}
    redis.eval lua_script, {keys: [comments_rank.key, comment_ids.key], argv: [comment.id]}
  end

  def paginate_comments(options = {})
    limit = [(options[:limit].presence || self.class.page_size).to_i, self.class.max_page_size].min
    return [] if limit == 0

    above_rank = options[:above_rank]
    above_comment_id = options[:above_comment_id]

    above_rank = if above_rank.present?
                   above_rank.to_i
                 elsif above_comment_id.present?
                   comment_ids[above_comment_id]
                 end

    return [] if above_rank && above_rank <= 0

    min = above_rank ? above_rank + 1 : '-inf'
    max = 'inf'

    ids = comment_ids.rangebyscore(min, max, {limit: limit})
    comments = Comment.pipelined_find(ids)

    # Delete any deleted comments from the list
    missing_comment_ids = ids - comments.map(&:id)

    if missing_comment_ids.present?
      comment_ids.delete(missing_comment_ids)
      paginate_comments(options)
    else
      comments
    end
  end
end
