# Include this module in a model class to make it submitted to the moderator
# for approval.
#
# You must implement:
#   #moderation_url that returns the URL of the image that moderators will
#     actually see.
#   #moderation_description that returns a string displayed to moderators
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

    response = HTTParty.post("#{Moderator.url}/api/photo/submit", body: {
      url: url, callback_url: Moderator.callback_url,
      key: Moderator.token, tasks: ['nudity'],
      passthru: {
        image_id: self.id,
        api_secret: Rails.configuration.app['api']['request_secret'],
      },
      description: description, info_url: info_url,
    })
    if [200,201,202].include?(response.code)
      self.status = 'review'
      self.save
    end
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
    end
  end

end
