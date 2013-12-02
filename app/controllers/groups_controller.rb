class GroupsController < ApplicationController
  skip_before_action :require_token, only: :show
  before_action :load_any_group, only: :show
  before_action :load_group, only: [:update, :leave]


  def create
    @group = current_user.created_groups.create!(params.permit(:name))
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def show
    objects = [@group, @group.members]
    objects += @group.paginate_messages(pagination_params) if current_user
    render_json objects
  end

  def update
    @group.update!(update_group_params)
    publish_to_group if @group.anything_changed
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def join
    @group = Group.find_by!(join_code: params[:join_code])

    # If this is a new member, publish the updated group to its channel
    if @group.add_member(current_user)
      publish_to_group
    end

    render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
  end

  def leave
    # If the member successfully left the group, publish the updated group to its channel
    if @group.leave!(current_user)
      publish_to_group
    end

    render_success
  end

  def is_member
    if Group.redis.sismember("group:#{params[:id]}:member_ids", current_user.id)
      render nothing: true
    else
      render nothing: true, status: :unauthorized
    end
  end


  private

  def load_any_group
    @group = if params[:id] && current_user
               Group.find(params[:id])
             elsif params[:join_code]
               Group.find_by!(join_code: params[:join_code])
             else
               raise ActiveRecord::RecordNotFound
             end
  end

  def load_group
    @group = current_user.groups.find(params[:id])
  end

  def update_group_params
    params.permit(:name, :topic, :wallpaper_image_file).tap do |attrs|
      if @group.admin?(current_user)
        if attrs.has_key?(:wallpaper_image_file) && attrs[:wallpaper_image_file].blank?
          attrs[:delete_wallpaper] = true
        else
          attrs[:wallpaper_creator_id] = current_user.id
        end
      else
        attrs.delete(:name)
        attrs.delete(:wallpaper_image_file)
      end
    end
  end

  def pagination_params
    params.permit(:limit, :below_rank)
  end

  def publish_to_group
    faye_publisher.publish_to_group(@group, GroupSerializer.new(@group).as_json)
  end
end
