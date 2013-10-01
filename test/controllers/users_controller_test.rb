require "test_helper"

describe UsersController do
  it "must say hello" do
    post :create
    response.body.must_equal '{"hello":"world"}'
  end
end
