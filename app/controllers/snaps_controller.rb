class SnapsController < ApplicationController
  def fetched
    unviewed_usernames = split_param(:unviewed_usernames)
    viewed_sent_usernames = split_param(:viewed_sent_usernames)
    viewed_received_usernames = split_param(:viewed_received_usernames)
    params[:trigger] = 'periodic_check' if params[:trigger].blank?

    unless current_user.mobile_notifier.pushes_enabled?
      unviewed_usernames.each do |username|
        current_user.email_notifier.notify_new_snap(username)
      end

      current_user.email_notifier.notify_missed_sent_snaps if viewed_sent_usernames.present?
      current_user.email_notifier.notify_missed_received_snaps if viewed_received_usernames.present?
    end

    increment_stories_metrics
    increment_content_push_metrics

    render_success
  end


  private

  def increment_stories_metrics
    count = params[:new_stories_count].to_i
    trigger = params[:trigger]

    StatsD.increment("stories.fetched.by_trigger.#{trigger}", count) if count > 0 && %w(periodic_check content_push).include?(trigger)
  end

  def increment_content_push_metrics
    return unless params[:trigger] == 'content_push'

    StatsD.increment('content_available_pushes.client_received')
    mixpanel.received_daily_content_push
  end
end
