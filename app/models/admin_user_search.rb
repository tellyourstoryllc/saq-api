class AdminUserSearch

  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def show_all?
    self.name.blank?
  end

  def to_scope
    #scp = User.joins(:account).where('accounts.registered_at IS NOT NULL')
    scp = User

    # Default to all registered users.
    return scp if show_all?

    if self.name =~ /@/
      scp.joins(:emails).where(emails: { email: self.name })
    else
      username = (self.name || '').strip.gsub(/\s+/, '%')
      scp.where("username like ?", "%#{username}%")
    end
  end

  def to_params
    { name: name }
  end

end
