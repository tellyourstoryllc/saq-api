require "test_helper"

describe UsersController do
  describe "POST /users" do
    describe "invalid" do
      it "must not create a user if it's invalid" do
        post :create
        result.must_equal('error' => {'message' => 'error'})
      end
    end


    describe "valid" do
      it "must create a user" do
        post :create, {name: 'John Doe', email: 'joe@example.com', password: 'asdf'}
        result['id'].must_be_instance_of Fixnum
        result.reject{ |k,v| k == 'id' }.must_equal('object_type' => 'user', 'name' => 'John Doe')
      end
    end
  end
end
