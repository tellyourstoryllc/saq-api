class GroupsController < ApplicationController
  skip_before_action :require_token, only: [:show, :find]
  before_action :load_group, only: [:update, :leave]
  before_action :load_group_by_join_code, only: [:find, :join]


  def create
    @group = current_user.created_groups.create!(params.permit(:name))
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def show
    @group = Group.find(params[:id])
    objects = [@group, @group.members]
    objects += @group.paginate_messages(pagination_params) if current_user && @group.member?(current_user)
    render_json objects
  end

  def find
    objects = [@group, @group.members]
    objects += @group.paginate_messages(pagination_params) if current_user && @group.member?(current_user)
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
    # If this is a new member, publish the updated group to its channel
    if @group.add_member(current_user)
      publish_updated_group(true)
    end

    render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
  end

  def leave
    # If the member successfully left the group, publish the updated group to its channel
    if @group.leave!(current_user)
      publish_updated_group
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

  def load_group
    @group = current_user.groups.find(params[:id])
  end

  def load_group_by_join_code
    @group = Group.find_by!(join_code: params[:join_code])
  end

  def update_group_params
    permitted = [:name, :topic, :avatar_image_file, :avatar_image_url, :wallpaper_image_file, :wallpaper_image_url]
    params.permit(permitted).tap do |attrs|
      if @group.admin?(current_user)
        if (attrs.has_key?(:avatar_image_file) && attrs[:avatar_image_file].blank?) ||
          (attrs.has_key?(:avatar_image_url) && attrs[:avatar_image_url].blank?)

          attrs[:delete_avatar] = true
        else
          attrs[:avatar_creator_id] = current_user.id
        end

        if (attrs.has_key?(:wallpaper_image_file) && attrs[:wallpaper_image_file].blank?) ||
          (attrs.has_key?(:wallpaper_image_url) && attrs[:wallpaper_image_url].blank?)

          attrs[:delete_wallpaper] = true
        else
          attrs[:wallpaper_creator_id] = current_user.id
        end
      else
        attrs_to_delete = [:name, :avatar_image_file, :avatar_image_url, :wallpaper_image_file, :wallpaper_image_url]
        attrs_to_delete.each{ |attr| attrs.delete(attr) }
      end
    end
  end

  def pagination_params
    params.permit(:limit, :below_rank)
  end

  def publish_updated_group(publish_to_self = false)
    data = GroupSerializer.new(@group).as_json

    faye_publisher.publish_to_group(@group, data)
    faye_publisher.publish_group_to_user(current_user, data) if publish_to_self
  end
end
