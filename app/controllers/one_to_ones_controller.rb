class OneToOnesController < ApplicationController
  before_action :load_one_to_one


  def show
    if @one_to_one.attrs.present?
      render_json [@one_to_one, *@one_to_one.members, @one_to_one.paginate_messages(pagination_params)]
    else
      render_json @one_to_one.members
    end
  end


  private

  def load_one_to_one
    @one_to_one = OneToOne.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @one_to_one.valid? && @one_to_one.authorized?(current_user)
  end

  def pagination_params
    params.permit(:limit, :last_message_id)
  end
end
