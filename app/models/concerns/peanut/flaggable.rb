module Peanut::Flaggable
  extend ActiveSupport::Concern

  def flag(flag_giver, flag_reason)
    submit_to_moderator if flag_reason.moderate? && submit_to_moderator?
    update_flag_metrics(flag_giver)
  end

  def submit_to_moderator?
    pending?
  end

  def update_flag_metrics(flag_giver)
    flag_giver.misc.incr('flags_given')
    flag_recipient.misc.incr('flags_received')
  end

  def flag_recipient
    user
  end
end
