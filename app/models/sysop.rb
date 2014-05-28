class Sysop < ActiveRecord::Base
  include Redis::Objects

  has_secure_password

  validates :name, uniqueness: true

  # A set of strings to indicate the permissions this sysop has.
  # 'superuser' is a special case
  set :permissions

  def has_permission?(perm)
    permissions.include?(perm)
  end

  def superuser?
    permissions.members.include?('superuser')
  end

  def set_token
    loop do
      self.token = SecureRandom.urlsafe_base64(16)
      break unless Sysop.where(token: token).exists?
    end
  end
end
