class StoriesController < ApplicationController
  before_action :load_story, only: [:show, :export]
  before_action :load_my_story, only: [:update, :delete]


  def show
    render_json @story
  end

  def update
    @story.update(update_params)
    load_my_story
    render_json @story
  end

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

  def delete
    @story.delete
    render_success
  end


  private

  def load_story
    @story = Story.new(id: params[:id])
  end

  def load_my_story
    @story = Story.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @story.attrs.exists? &&
      @story.user_id == current_user.id
  end

  def update_params
    params.slice(:story_permission, :latitude, :longitude, :source, :attachment_overlay_file,
                 :attachment_overlay_text)
  end
end
