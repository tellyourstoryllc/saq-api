class GroupsController < ApplicationController
  skip_before_action :require_token, only: [:show, :find]
  before_action :load_group, only: [:update, :leave, :add_users]


  def create
    @group = current_user.created_groups.create!(params.permit(:name))
    group_mixpanel.group_created(@group)
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def show
    throttle_failed_attempts do
      @group = Group.find(params[:id])
    end

    @group.viewer = current_user
    objects = [@group, @group.members]
    objects += @group.paginate_messages(pagination_params) if current_user && @group.member?(current_user)
    render_json objects
  end

  def find
    throttle_failed_attempts do
      @group = Group.find_by!(join_code: params[:join_code])
    end

    objects = [@group, @group.members]
    objects += @group.paginate_messages(pagination_params) if current_user && @group.member?(current_user)
    render_json objects
  end

  def update
    @group.viewer = current_user
    @group.update!(update_group_params)
    publish_updated_group if update_group_params.keys.any?{ |k| ! %w(last_seen_rank hidden).include?(k) }
    group_mixpanel.fetched_daily_messages(@group) if update_group_params.keys.include?('last_seen_rank')

    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def join
    throttle_failed_attempts do
      @group = Group.find_by!(join_code: params[:join_code])
    end

    result = @group.add_member(current_user)

    if result
      unless result == :already_member
        notify_admins
        mixpanel.joined_group(@group)
      end

      render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
    else
      render_error "Sorry, you cannot join that group at this time."
    end
  end

  def leave
    @group.leave!(current_user)
    render_success
  end

  def is_member
    if Group.redis.sismember("group:#{params[:id]}:member_ids", current_user.id)
      render nothing: true
    else
      render nothing: true, status: :unauthorized
    end
  end

  def add_users
    user_ids = split_param(:user_ids)
    emails = split_param(:emails)
    phone_numbers = split_param(:phone_numbers)
    phone_names = split_param(:phone_names)

    group_inviter = GroupInviter.new(current_user, @group)
    group_inviter.add_users(user_ids)
    group_inviter.add_by_emails(emails)
    group_inviter.add_by_phone_numbers(phone_numbers, phone_names)

    normalized_emails = emails.map {|e| Email.normalize(e) }.compact
    normalized_numbers = phone_numbers.map {|n| Phone.normalize(n) }.compact

    users = []
    users = users | User.where(id: user_ids) if user_ids.present?
    users = users | User.joins(:emails).where(emails: {email: normalized_emails}) if normalized_emails.present?
    users = users | User.joins(:phones).where(phones: {number: normalized_numbers}) if normalized_numbers.present?

    render_json [@group] + users
  end


  private

  def throttle_failed_attempts(&block)
    begin
      yield
    rescue ActiveRecord::RecordNotFound
      increment_failed_attempts
      raise
    end

    check_failed_attempts
  end

  def check_failed_attempts
    raise ActiveRecord::RecordNotFound if !@group.member?(current_user) && over_limit?
  end

  def over_limit?
    user_key = user_locked_key
    ip_key = ip_locked_key

    results = User.redis.pipelined do
      User.redis.exists(user_key) if user_key
      User.redis.exists(ip_key)
    end

    results.any?
  end

  def increment_failed_attempts
    return if over_limit?

    max_attempts = 15
    within_period = 60.seconds
    lockout_period = 1.hour

    if current_user
      _, attempts = User.redis.multi do
        User.redis.set(user_failed_key, 0, {ex: within_period, nx: true})
        User.redis.incr(user_failed_key)
      end

      User.redis.set(user_locked_key, 1, {ex: lockout_period}) if attempts >= max_attempts
    end

    _, attempts = User.redis.multi do
      User.redis.set(ip_failed_key, 0, {ex: within_period, nx: true})
      User.redis.incr(ip_failed_key)
    end

    User.redis.set(ip_locked_key, 1, {ex: lockout_period}) if attempts >= max_attempts
  end

  def user_failed_key
    "user:#{current_user.id}:failed_group_attempts" if current_user
  end

  def user_locked_key
    "user:#{current_user.id}:locked_from_new_groups" if current_user
  end

  def ip_failed_key
    "ip:#{remote_ip}:failed_group_attempts"
  end

  def ip_locked_key
    "ip:#{remote_ip}:locked_from_new_groups"
  end

  def load_group
    @group = current_user.groups.find(params[:id])
  end

  def update_group_params
    permitted = [:name, :topic, :avatar_image_file, :avatar_image_url, :wallpaper_image_file,
      :wallpaper_image_url, :last_seen_rank, :hidden]
    params.permit(permitted).tap do |attrs|
      if @group.admin?(current_user)
        if (attrs.has_key?(:avatar_image_file) && attrs[:avatar_image_file].blank?) ||
          (attrs.has_key?(:avatar_image_url) && attrs[:avatar_image_url].blank?)

          attrs[:delete_avatar] = true
        elsif attrs[:avatar_image_file].present? || attrs[:avatar_image_url].present?
          attrs[:avatar_creator_id] = current_user.id
        end

        if (attrs.has_key?(:wallpaper_image_file) && attrs[:wallpaper_image_file].blank?) ||
          (attrs.has_key?(:wallpaper_image_url) && attrs[:wallpaper_image_url].blank?)

          attrs[:delete_wallpaper] = true
        elsif attrs[:wallpaper_image_file].present? || attrs[:wallpaper_image_url].present?
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

  def publish_updated_group
    faye_publisher.publish_group_to_user(current_user, GroupSerializer.new(@group).as_json)
  end

  def notify_admins
    @group.admins.each do |user|
      user.mobile_notifier.notify_new_member(current_user, @group)
      user.email_notifier.notify_new_member(current_user, @group)
    end
  end
end
