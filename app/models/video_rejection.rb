class VideoRejection < ActiveRecord::Base
  before_validation :fix_video_moderation_reject_reason_id
  belongs_to :video_moderation_reject_reason


  def message_to_user
    if video_moderation_reject_reason
      video_moderation_reject_reason.message_to_user
    else
      custom_message_to_user
    end
  end


  private

  def fix_video_moderation_reject_reason_id
    self.video_moderation_reject_reason_id ||= VideoModerationRejectReason.find_default.id if message_to_user.blank?
  end
end
