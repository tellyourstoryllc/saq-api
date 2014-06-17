class StoriesController < ApplicationController
  before_action :load_story, only: :export


  def search
    story_usernames = split_param(:story_usernames)
    snapchat_media_ids = split_param(:snapchat_media_ids)

    render_json Story.existing_snapchat_media_ids(story_usernames, snapchat_media_ids)
  end

  def export
    exported = @story.record_export(current_user, params[:method])
    @story.user.send_export_notifications(@story, current_user, params[:method]) if exported
    render_success
  end


  private

  def load_story
    @story = Story.new(id: params[:id])
  end
end
