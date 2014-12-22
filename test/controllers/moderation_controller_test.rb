require "test_helper"

describe ModerationController do
  before do
    stub_request(:any, /#{Rails.configuration.app['aws']['bucket_name']}/).to_return(status: 204, headers: { 'ETag' => 'abc' })
  end

  describe "when approving" do
    let(:user) { FactoryGirl.create(:registered_user, public_avatar_image: false) }

    it "should set user public_avatar_image to true" do
      image = FactoryGirl.build(:avatar_image, user: user)
      image[:image] = 'fake.png'
      image.save!
      # Precondition.  Avatar is in review.
      user.reload
      user.avatar_image.must_be :in_review?

      # Call the callback.
      post :callback, image_id: image.id, passed: ['nudity']

      # Postcondition.
      user.reload
      user.public_avatar_image.must_equal true
    end
  end

  describe "when censoring" do
    let(:user) { FactoryGirl.create(:registered_user, public_avatar_image: true) }

    it "should set user public_avatar_image to false" do
      image = FactoryGirl.build(:avatar_image, user: user)
      image[:image] = 'fake.png'
      image.save!
      # Precondition.  Avatar is in review.
      user.reload
      user.avatar_image.must_be :in_review?

      # Call the callback.
      post :callback, image_id: image.id, failed: ['nudity']

      # Postcondition.
      user.reload
      user.public_avatar_image.must_equal false
    end
  end
end
