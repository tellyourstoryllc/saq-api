class OneToOnesController < ApplicationController
  before_action :load_one_to_one


  def show
    if @one_to_one.attrs.present?
      objects = [@one_to_one, @one_to_one.other_user(current_user).account, *@one_to_one.members]
      objects += @one_to_one.paginate_messages(message_pagination_params) unless @one_to_one.pending?(current_user)
      render_json objects
    else
      render_json @one_to_one.members
    end
  end

  def update
    update_params.each do |k,v|
      @one_to_one.send("#{k}=", v)
    end

    # Reload the 1-1
    load_one_to_one

    publish_updated_one_to_one
    render_json @one_to_one
  end


  private

  def load_one_to_one
    @one_to_one = OneToOne.new(id: params[:id])
    @one_to_one.viewer = current_user

    raise Peanut::Redis::RecordNotFound unless @one_to_one.valid? && @one_to_one.authorized?(current_user)
  end

  def update_params
    params.permit(:last_seen_rank, :last_deleted_rank, :hidden)
  end

  def publish_updated_one_to_one
    faye_publisher.publish_one_to_one_to_user(current_user, OneToOneSerializer.new(@one_to_one).as_json)
  end
end
