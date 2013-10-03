require "test_helper"

describe User do
  let(:user) { User.new(name: 'Joe', email: 'joe@example.com', password: 'asdf') }

  it "must be valid" do
    user.valid?.must_equal true
  end
end
