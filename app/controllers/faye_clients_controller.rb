class FayeClientsController < ApplicationController
  before_action :load_faye_client


  def update
    @faye_client.user_id = current_user.id
    @faye_client.status = params[:status]
    @faye_client.client_type = params[:client_type]
    @faye_client.idle_duration = params[:idle_duration]

    old_status = current_user.computed_status

    if @faye_client.save
      new_status = current_user.computed_status(true)
      current_user.reset_digests_if_needed(old_status, new_status)

      render_json current_user
    else
      render_error @faye_client.errors.full_messages
    end
  end


  private

  def load_faye_client
    @faye_client = FayeClient.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound if @faye_client.attrs.present? && @faye_client.user_id != current_user.id
  end
end
