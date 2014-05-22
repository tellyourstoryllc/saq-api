class SnapsController < ApplicationController
  def fetched
    unviewed_usernames = split_param(:unviewed_usernames)
    viewed_sent_usernames = split_param(:viewed_sent_usernames)
    viewed_received_usernames = split_param(:viewed_received_usernames)

    unless current_user.mobile_notifier.pushes_enabled?
      unviewed_usernames.each do |username|
        current_user.email_notifier.notify_new_snap(username)
      end

      current_user.email_notifier.notify_missed_sent_snaps if viewed_sent_usernames.present?
      current_user.email_notifier.notify_missed_received_snaps if viewed_received_usernames.present?
    end

    render_success
  end
end
