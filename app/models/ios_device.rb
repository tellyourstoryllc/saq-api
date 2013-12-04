class IosDevice < ActiveRecord::Base
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user


  def self.create_or_assign!(user, attrs)
    return if attrs[:device_id].blank?

    ios_device = where(device_id: attrs[:device_id]).first_or_initialize
    ios_device.update!(attrs.merge(user_id: user.id))
  end

  def unassign!
    update!(user_id: nil)
  end
end
