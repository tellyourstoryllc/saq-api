require "test_helper"

describe "Admin Integration Test" do
  let(:user) { FactoryGirl.create(:registered_user) }

  let(:sysop) { Sysop.create!(name: 'name', password: 'password', password_confirmation: 'password') }

  before do
    # Create a sysop with permission to everything.
    sysop.permissions << 'superuser'
    # Create token.
    sysop.set_token
    sysop.save!

    # Force creation of the user.
    user
  end

  describe "GET /admin/users" do
    it "must list users" do
      cookies[:admin_token] = sysop.token
      get '/admin/users'
      assert_response :success
    end

    describe "when not authenticated" do
      it "must redirect to login" do
        cookies[:admin_token] = 'bogus'
        get '/admin/users'
        assert_redirected_to controller: 'admin_auth', action: 'login'
      end
    end
  end

  describe "GET /admin/users/:id" do
    it "must show user" do
      cookies[:admin_token] = sysop.token
      get "/admin/users/#{user.id}"
      assert_response :success
    end
  end

  describe "GET /admin/users/:id/contacts" do
    it "must show user contacts" do
      # Create a contact.
      u2 = FactoryGirl.create(:registered_user)
      inviter = ContactInviter.new(user)
      inviter.add_user(user, u2)
      inviter.add_user(u2, user)

      cookies[:admin_token] = sysop.token
      get "/admin/users/#{user.id}/contacts"
      assert_response :success
    end
  end
end
