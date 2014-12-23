module Peanut::Flaggable
  extend ActiveSupport::Concern

  included do
    set :flagger_ids
  end

  def flag(flag_giver, flag_reason)
    submit_to_moderator if flag_reason.moderate? && submit_to_moderator?
    update_flag_metrics(flag_giver)
  end

  def submit_to_moderator?
    pending?
  end

  def update_flag_metrics(flag_giver)
    if flagger_ids.add(flag_giver.id)
      flag_giver.misc.incr('flags_given')
      flag_recipient.misc.incr('flags_received')
    end
  end

  def flag_recipient
    user
  end
end
