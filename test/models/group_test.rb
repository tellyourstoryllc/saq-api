require "test_helper"

describe Group do
  let(:group) { Group.new(creator_id: 1, name: 'Cool Dudes') }

  it "must be valid" do
    group.valid?.must_equal true
  end
end
