class AdminController < ActionController::Base
  before_action :authenticate, :require_sysop
  around_filter :set_time_zone
  before_action :load_user, only: [:show_user, :show_user_contacts]
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
    @today = Time.zone.today
    @days = 14

    fetch_friend_metrics
    fetch_message_metrics
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

  def show_user_contacts
    @offset = params[:offset].to_i
    @contacts = @user.paginated_contacts(limit: 50, offset: @offset)
    @contacts_count = @user.contact_ids.size
  end


  protected

  def logged_in?
    !! @sysop
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
    @sysop = Sysop.find_by_token(cookies[:admin_token]) if cookies[:admin_token].present?
  end

  def require_sysop
    redirect_to admin_login_path unless @sysop && self.class.required_permissions.any? {|perm| @sysop.has_permission?(perm) }
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

  def fetch_friend_metrics
    @friend_counts = {}

    @days.times do |i|
      registered_date = @today - i
      registered_from = Time.zone.local_to_utc(registered_date.to_datetime).to_s(:db)
      registered_to = Time.zone.local_to_utc((registered_date + 1).to_datetime - 1.second).to_s(:db)
      @friend_counts[registered_date.to_s] = {}

      User.joins(:account).where('accounts.registered_at BETWEEN ? AND ?', registered_from, registered_to).find_each do |u|
        contact_ids = u.contact_ids.members
        contacts = User.includes(:account).where(id: contact_ids).to_a
        contacts_count = contacts.size

        @days.times do |j|
          action_date = (@today - j)
          next if action_date < registered_date || !u.active_on?(action_date)

          @friend_counts[registered_date.to_s][action_date.to_s] ||= {}
          @friend_counts[registered_date.to_s][action_date.to_s][u.id] ||= {}

          registered_count = contacts.count{ |c| c.account.registered_at.present? && c.account.registered_at.to_date <= action_date }
          @friend_counts[registered_date.to_s][action_date.to_s][u.id]['contacts_counts'] = contacts_count
          @friend_counts[registered_date.to_s][action_date.to_s][u.id]['registered_counts'] = registered_count
          @friend_counts[registered_date.to_s][action_date.to_s][u.id]['percent_registered'] = (registered_count.to_f / contacts_count) * 100 if contacts_count > 0
        end
      end
    end
  end

  def fetch_message_metrics
    @raw = {}
    @sent = {}
    @received = {}

    User.redis.pipelined do
      @days.times do |i|
        registered_date = (@today - i).to_s
        key = User.cohort_metrics_key(registered_date)
        @raw[registered_date] = User.redis.hgetall(key)
      end
    end

    @days.times do |i|
      registered_date = (@today - i).to_s
      metrics = @raw[registered_date].value

      registered_key = "registered_on_#{registered_date}"
      @sent[registered_key] = {}
      @received[registered_key] = {}

      @days.times do |j|
        action_date = (@today - j).to_s

        reg = metrics["sent_to_registered_#{action_date}"].to_f
        unreg = metrics["sent_to_unregistered_#{action_date}"].to_f
        @sent[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0 || unreg > 0

        reg = metrics["received_from_registered_#{action_date}"].to_f
        unreg = metrics["received_from_unregistered_#{action_date}"].to_f
        @received[registered_key]["action_on_#{action_date}"] = (reg / (reg + unreg)) * 100 if reg > 0 || unreg > 0
      end
    end
  end
end
