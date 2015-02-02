class VideoModerationRejectReason < ActiveRecord::Base
  scope :active, -> { where(active: true) }

  def as_json(options = {})
    {id: id, title: title}
  end

  def self.find_default
    where(default_reason: true).first
  end
end
