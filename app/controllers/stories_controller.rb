class StoriesController < ApplicationController
  before_action :load_story, only: [:show, :export, :flag]
  before_action :load_my_story, only: [:update, :delete]


  def show
    render_json @story
  end

  def update
    pushed_user_ids = @story.update(update_params)

    # Notify the users to whose feed this story was just added
    User.where(id: pushed_user_ids).find_each do |user|
      user.send_story_notifications(@story)
    end

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

  def flag
    @flag_reason = FlagReason.find(params[:flag_reason_id]) if params[:flag_reason_id].present?

    if @flag_reason.nil?
      render_error 'Invalid flag_reason_id'
    else
      @story.flag(current_user, @flag_reason)
      render_json @story
    end
  end

  def tagged
    render_json Story.search_by_tag(params[:tag], pagination_params)
  end


  private

  def load_story
    @story = Story.new(id: params[:id])
    raise Peanut::UnauthorizedError unless @story.has_permission?(current_user)
  end

  def load_my_story
    @story = Story.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @story.attrs.exists? &&
      @story.user_id == current_user.id
  end

  def update_params
    params.slice(:permission, :latitude, :longitude, :source, :attachment_overlay_file,
                 :attachment_overlay_text, :has_face)
  end
end
