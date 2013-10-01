require "test_helper"

describe User do
  let(:user) { User.new }

  it "must be valid" do
    user.valid?.must_equal true
  end
end
