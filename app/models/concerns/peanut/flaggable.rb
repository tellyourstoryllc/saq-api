module Peanut::Flaggable
  extend ActiveSupport::Concern

  INITIAL_FLAGS_GRACE_LEVEL = 10
  included do
    set :flagger_ids
    set :initial_flagger_ids
    attr_accessor :flag_reason
  end


  def flag(flag_giver, flag_reason = nil)
    return if bad_flagger?(flag_giver)

    self.flag_reason = flag_reason

    submit_to_moderator if submit_to_moderator?
    update_flag_metrics(flag_giver)
  end

  def submit_to_moderator?
    (!flag_reason || flag_reason.moderate?) && pending?
  end

  def update_flag_metrics(flag_giver)
    if flagger_ids.add(flag_giver.id)
      flag_recipient.misc.incr('flags_received')
      flag_giver.misc.incr('flags_given')

      if pending? || review?
        flag_giver.misc.incr('initial_flags_given')
        initial_flagger_ids << flag_giver.id
      end
    end
  end

  def flag_recipient
    user
  end

  def bad_flagger?(flag_giver)
    flag_giver.misc['initial_flags_given'].to_i >= INITIAL_FLAGS_GRACE_LEVEL &&
      successful_flags_percentage(flag_giver) < 0.5
  end

  def successful_flags_percentage(flag_giver)
    counts = flag_giver.misc.bulk_get('initial_flags_given', 'initial_flags_censored')
    given = counts['initial_flags_given']
    censored = counts['initial_flags_censored']

    given.nil? ? 0.0 : censored.to_f / given.to_f
  end
end
