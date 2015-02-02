# Include this module in a model class to make it submitted to the moderator
# for approval.
#
# You must implement:
#   #moderation_url that returns the URL of the image that moderators will
#     actually see.
#   #moderation_description that returns a string displayed to moderators
#   #moderation_type that returns either :photo or :video. default: :photo
#   #moderation_increment_flags_censored? that returns either true or false
#
# Preconditions:
#   #status must == 'pending' in order to submit to the moderator for reviewing.
#
# Hooks:
#   before, after, and around hooks for the following:
#   - moderation_approve
#   - moderation_censor
module Peanut::SubmittedForYourApproval

  def self.included(base)
    base.class_eval do
      #after_save :submit_to_moderator
      define_model_callbacks :moderation_approve, :moderation_censor
    end
  end

  def pending?; self.status == 'pending'; end
  def in_review?; self.status == 'review'; end
  alias_method :review?, :in_review?
  def censored?; self.status == 'censored'; end
  def approved?; self.status == 'normal';   end

  def moderation_type
    :photo
  end

  def moderation_increment_flags_censored?
    false
  end

  def submit_to_moderator
    return unless pending?

    url = moderation_url
    return unless url && self.id

    unless Moderator.url && Moderator.callback_url && Moderator.token
      Rails.logger.warn "Moderator not configured; skipping #submit_to_moderator"
      return
    end

    description = moderation_description
    description ||= "(#{Rails.env}): #{self.class.name} #{self.id}"
    info_url = nil

    type = moderation_type
    return unless [:photo, :video].include?(type)

    endpoint = "#{Moderator.url}/api/#{type}/submit"

    response = HTTParty.post(endpoint, body: {
      url: url, callback_url: Moderator.callback_url,
      key: Moderator.token, tasks: ['nudity'],
      passthru: {
        model_id: self.id,
        model_class: self.class.to_s,
        api_secret: Rails.configuration.app['api']['request_secret'],
      },
      description: description, info_url: info_url,
      reject_reasons: VideoModerationRejectReason.active.as_json
    })

    if [200,201,202].include?(response.code)
      review!
    end
  end

  def review!
    self.status = 'review'
    self.save
  end

  def approve!
    run_callbacks :moderation_approve do
      self.status = 'normal'
      self.save
    end
  end

  def censor!
    run_callbacks :moderation_censor do
      self.status = 'censored'
      self.save

      increment_flags_censored if moderation_increment_flags_censored?
    end
  end

  def increment_flags_censored
    flagger_ids = initial_flagger_ids.members

    if flagger_ids.present?
      User.where(id: flagger_ids).find_each do |flagger|
        flagger.misc.incr('initial_flags_censored')
      end
    end
  end

  def auto_censor!
    @auto_censored = true
    censor!
  end

  def add_censored_object
    user.add_censored_object(self) unless @auto_censored
  end
end
