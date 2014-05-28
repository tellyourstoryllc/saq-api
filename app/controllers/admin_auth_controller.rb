class AdminAuthController < AdminController
  skip_before_action :require_sysop

  def login
    if request.post? || request.put?
      @sysop = Sysop.find_by_name(params[:name]).try(:authenticate, params[:password])
      if @sysop
        @sysop.set_token
        @sysop.save
        cookies[:admin_token] = @sysop.token
      end
    end

    # Either we just logged in or someone is doing a GET on login when already
    # logged in.
    if @sysop
      if @sysop.superuser?
        redirect_to :admin_users
      elsif @sysop.permissions.members.any?
        redirect_to "admin_#{@sysop.permissions.members.first}".to_sym
      end

    elsif params[:name].present?
      flash.now[:notice] = 'Incorrect name or password'
    end
  end

  def logout
    cookies[:admin_token] = nil
    redirect_to :admin_login
  end

end
