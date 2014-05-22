class SnapsController < ApplicationController
  def fetched
    unviewed_usernames = split_param(:unviewed_usernames)

    unless current_user.mobile_notifier.pushes_enabled?
      unviewed_usernames.each do |username|
        current_user.email_notifier.notify_new_snap(username)
      end
    end

    render_success
  end
end
