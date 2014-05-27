class ConversationsController < ApplicationController
  def index
    # TODO: manual ordering

    groups = current_user.groups.includes(:group_avatar_image, :group_wallpaper_image)
    one_to_ones = current_user.one_to_ones

    # Special case the robot user.
    if Robot.bot?(current_user)
      # Don't return conversations with only the intro messages sent by the
      # robot.
      num_intro_messages = RobotItem.by_trigger('intro').count
      one_to_ones = one_to_ones.select{ |o| o.rank.get > num_intro_messages }
    end

    conversations = groups + one_to_ones

    # To be backward compatible with old clients, return all conversations when
    # no limit is specified.
    if params[:limit].present?
      limit = params[:limit].to_i
      limit = 500 if limit > 500
      limit = 0 if limit < 0
      offset = params[:offset].to_i

      # Sort in a way that's consistent between calls.
      conversations.sort_by!{ |convo| [convo.created_at, convo.id] }

      conversations = conversations[offset, limit]
    end

    conversations.each{ |convo| convo.viewer = current_user }
    other_user_ids = conversations.map{ |c| c.other_user_id(current_user) if c.respond_to?(:other_user_id) }.compact
    other_users = User.includes(:avatar_image, :avatar_video).where(id: other_user_ids)

    render_json conversations + other_users
  end
end
