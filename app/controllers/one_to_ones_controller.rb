class OneToOnesController < ApplicationController
  before_action :load_one_to_one


  def show
    render_json [@one_to_one, @one_to_one.sender, @one_to_one.recipient, @one_to_one.paginate_messages(pagination_params)]
  end


  private

  def load_one_to_one
    @one_to_one = OneToOne.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @one_to_one.attrs.present? && @one_to_one.authorized?(current_user)
  end

  def pagination_params
    params.permit(:limit, :last_message_id)
  end
end
