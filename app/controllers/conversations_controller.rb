class ConversationsController < ApplicationController
  def index
    # TODO: manual ordering

    @one_to_ones = current_user.one_to_ones

    # Special case the robot user.
    if Robot.bot?(current_user)
      # Don't return conversations with only the intro messages sent by the
      # robot.
      num_intro_messages = RobotItem.by_trigger('intro').count
      @one_to_ones = @one_to_ones.select{ |o| o.rank.get > num_intro_messages }
    end

    # To be backward compatible with old clients, return all 1-1s when
    # no limit is specified.
    if params[:limit].present?
      limit = params[:limit].to_i
      limit = 500 if limit > 500
      limit = 0 if limit < 0
      offset = params[:offset].to_i

      # Sort in a way that's consistent between calls.
      @one_to_ones.sort_by!{ |o| [o.created_at, o.id] }

      @one_to_ones = @one_to_ones[offset, limit]
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
    messages = []

    @one_to_ones.each do |o|
      messages += o.paginate_unseen_messages(limit: limit)
    end

    messages
  end
end
