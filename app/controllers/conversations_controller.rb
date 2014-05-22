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
    conversations.each{ |convo| convo.viewer = current_user }
    other_users = User.includes(:avatar_image, :avatar_video).where(id: one_to_ones.map{ |o| o.other_user_id(current_user) })

    render_json conversations + other_users
  end
end
