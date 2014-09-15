class BlacklistedUsernamesController < ApplicationController
  def add
    usernames = split_param(:usernames)
    existing_usernames = Settings.get_list(:blacklisted_usernames)

    usernames = (existing_usernames | usernames).map(&:strip).reject(&:empty?).sort.join(',')
    Settings.set(:blacklisted_usernames, usernames)

    render_json Settings.get_list(:blacklisted_usernames)
  end
end
