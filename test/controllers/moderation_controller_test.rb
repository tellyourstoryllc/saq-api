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
      image.submit_to_moderator

      # Precondition.  Avatar is in review.
      user.reload
      user.avatar_image.must_be :in_review?

      # Call the callback.
      post :callback, model_id: image.id, model_class: 'AvatarImage', passed: ['nudity'], api_secret: Rails.configuration.app['api']['request_secret']

      # Postcondition.
      user.reload
      user.avatar_image.must_be :approved?
      user.public_avatar_image.must_equal true
    end
  end

  describe "when censoring" do
    let(:user) { FactoryGirl.create(:registered_user, public_avatar_image: true) }

    it "should set user public_avatar_image to false" do
      user.update(public_avatar_image: true)

      image = FactoryGirl.build(:avatar_image, user: user)
      image[:image] = 'fake.png'
      image.save!
      image.submit_to_moderator

      # Precondition.  Avatar is in review.
      user.reload
      user.avatar_image.must_be :in_review?

      # Call the callback.
      post :callback, model_id: image.id, model_class: 'AvatarImage', failed: ['nudity'], api_secret: Rails.configuration.app['api']['request_secret']

      # Postcondition.
      user.reload
      user.avatar_image.must_be :censored?
      user.public_avatar_image.must_equal false
    end
  end
end
