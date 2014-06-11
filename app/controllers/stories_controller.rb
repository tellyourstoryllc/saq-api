class StoriesController < ApplicationController
  def search
    story_usernames = split_param(:story_usernames)
    snapchat_media_ids = split_param(:snapchat_media_ids)

    render_json Story.existing_snapchat_media_ids(story_usernames, snapchat_media_ids)
  end
end
