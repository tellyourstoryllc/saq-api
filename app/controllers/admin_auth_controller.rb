class AdminAuthController < AdminController
  skip_before_action :require_sysop, only: [:login, :logout, :forgot_password, :send_reset_password_email]

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
      redirect_to_default
    elsif params[:name].present?
      flash.now[:alert] = 'Incorrect name or password'
    end
  end

  def logout
    cookies[:admin_token] = nil
    redirect_to :admin_login
  end

  def forgot_password
  end

  def send_reset_password_email
    login = params[:login]
    sysop = Sysop.find_by_name(login) || Sysop.find_by_email(login)
    if sysop.try(:email)
      AdminMailer.password_reset(sysop).deliver!
    else
      flash.now[:alert] = "Account either was not found or does not have an email address associated.  Please contact an admin."
      render 'forgot_password'
    end
  end

  def reset_password
  end

  def update_password
    current_sysop.password = current_sysop.password_confirmation = params[:password]
    if current_sysop.password.blank?
      flash.now[:alert] = "Password must not be blank."
      render 'reset_password'
      return
    end

    if current_sysop.save
      flash[:notice] = "Password updated."
      redirect_to_default
    else
      flash.now[:alert] = current_sysop.errors.full_messages
      render 'reset_password'
    end
  end


  private

  def redirect_to_default
    if @sysop.superuser?
      redirect_to :admin_users
    elsif @sysop.permissions.members.any?
      redirect_to "admin_#{@sysop.permissions.members.first}".to_sym
    end
  end
end
