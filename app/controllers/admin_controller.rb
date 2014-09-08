class AdminController < ActionController::Base
  before_action :authenticate, :require_sysop
  around_filter :set_time_zone
  before_action :load_user, only: [:show_user, :show_user_friends]
  helper :admin
  helper_method :logged_in?


  def sms_stats
    @today = Time.zone.today

    @daily_sent_sms_counts = HookClient.daily_sent_sms_counts.all
    @monthly_sent_sms_counts = HookClient.monthly_sent_sms_counts.all
    @all_time_sent_sms_count = HookClient.all_time_sent_sms_count.get

    @daily_received_sms_counts = HookClient.daily_received_sms_counts.all
    @monthly_received_sms_counts = HookClient.monthly_received_sms_counts.all
    @all_time_received_sms_count = HookClient.all_time_received_sms_count.get

    @daily_error_counts = HookClient.daily_error_counts.all
    @monthly_error_counts = HookClient.monthly_error_counts.all
    @all_time_error_count = HookClient.all_time_error_count.get
  end

  def cohort_metrics
    @admin_metrics = AdminMetrics.new
    @today = @admin_metrics.today
    @days = AdminMetrics::DAYS

    @friend_counts = @admin_metrics.fetch_friend_metrics
    @friend_counts_in_progress = @admin_metrics.in_progress?

    @sent, @received = @admin_metrics.fetch_message_metrics
  end

  def users
    @user_search = AdminUserSearch.new(params[:name])

    @users = @user_search.to_scope
    @users = @users.reorder(created_at: :desc)
    @users_count = @users.count
    @offset = params[:offset].to_i
    @users = @users.limit((params[:limit].presence || 30).to_i).offset(@offset)
  end

  def show_user
  end

  def show_user_friends
    @offset = params[:offset].to_i
    @friends = @user.paginated_snapchat_friends(limit: 50, offset: @offset)
    @friends_count = @user.snapchat_friend_ids.size
  end

  def settings
    @settings = {blacklisted_usernames: Settings.get(:blacklisted_usernames)}
  end

  def edit_setting
    @key = params[:key]
    @value = Settings.get(@key)
  end

  def update_setting
    val = params[:value]
    val = val.split(',').map(&:strip).reject(&:empty?).uniq.sort.join(',')
    Settings.set(params[:key], val)

    redirect_to admin_settings_path
  end


  protected

  def current_sysop
    @sysop
  end

  def logged_in?
    !! current_sysop
  end


  private

  def self.required_permissions
    @@required_permissions ||= []
  end

  def self.require_permission(permission)
    required_permissions << permission
  end

  # Superuser can access all admin tools.
  require_permission :superuser

  def authenticate
    # Allow params to override cookies.
    if params[:admin_token].present?
      t = params[:admin_token]
      @sysop = Sysop.find_by_token(t)
      # Save token to cookies if it's valid.
      cookies[:admin_token] = t if @sysop
    end
    if ! @sysop && cookies[:admin_token].present?
      @sysop = Sysop.find_by_token(cookies[:admin_token])
    end
  end

  def require_sysop
    unless @sysop
      redirect_to admin_login_path; return
    end
    unless self.class.required_permissions.any? {|perm| @sysop.has_permission?(perm) }
      flash.now[:alert] = "You don't have permission to view this page."
      render 'error'
    end
  end

  def load_user
    @user = User.find(params[:id])
  end

  def set_time_zone
    old_time_zone = Time.zone
    Time.zone = 'Eastern Time (US & Canada)'
    yield
  ensure
    Time.zone = old_time_zone
  end
end
