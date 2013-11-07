class ConversationsController < ApplicationController
  def index
    # TODO: manual ordering
    render_json current_user.conversations
  end
end
