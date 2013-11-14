class CheckinController < ApplicationController
  def index
    objects = []

    meta = {
      object_type: 'meta',
      emoticons: {
        version: Emoticon::VERSION
      }
    }

    objects << meta
    objects << current_user
    objects << current_user.preferences
    objects += Emoticon.by_version(params[:emoticons_version])

    render_json objects
  end
end
