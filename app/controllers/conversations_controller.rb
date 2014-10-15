class ConversationsController < ApplicationController
  def index
    limit = params[:limit].presence
    limit ||= 50 if Robot.bot?(current_user)

    # To be backward compatible with old clients, return all 1-1s when
    # no limit is specified.
    if limit.present?
      @one_to_ones = current_user.paginated_one_to_ones(offset: params[:offset], limit: limit)
    else
      @one_to_ones = current_user.one_to_ones
    end

    # Special case the robot user.
    if Robot.bot?(current_user)
      # Don't return conversations with only the intro messages sent by the
      # robot.
      num_intro_messages = RobotItem.by_trigger('intro').count
      @one_to_ones = @one_to_ones.select{ |o| o.rank.get > num_intro_messages }
    end

    @one_to_ones.each{ |o| o.viewer = current_user }
    other_user_ids = @one_to_ones.map{ |c| c.other_user_id(current_user) if c.respond_to?(:other_user_id) }.compact
    other_users = User.includes(:account, :avatar_image, :avatar_video).where(id: other_user_ids)

    unseen_messages = fetch_unseen_messages

    render_json @one_to_ones + other_users + unseen_messages
  end


  private

  def fetch_unseen_messages
    limit = params[:limit]
    last_seen_ranks = params[:last_seen_ranks].present? ? params[:last_seen_ranks] : {}
    last_seen_ranks = JSON.parse(last_seen_ranks) if last_seen_ranks.is_a?(String)
    messages = []

    @one_to_ones.each do |o|
      rank = last_seen_ranks[o.id]
      messages += o.paginate_unseen_messages(last_seen_rank: rank, limit: limit)
    end

    messages
  end
end
