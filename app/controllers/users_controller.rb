class UsersController < ApplicationController
  def create
    render json: {hello: 'world'}
  end
end
