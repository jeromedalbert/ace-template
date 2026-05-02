require 'rails_helper'

describe SessionsController do
  describe '#new' do
    before { get :new }

    it { should respond_with :ok }
  end

  describe '#create' do
    context 'when credentials are invalid' do
      before { post :create, params: { email: some_value, password: some_value } }

      it { should redirect_to new_session_path }
    end

    context 'when credentials are valid' do
      before do
        create(:user, email: 'john@test.com', password: 'abc123')

        post :create, params: { email: 'john@test.com', password: 'abc123' }
      end

      it { should redirect_to root_path }
    end
  end

  describe '#destroy' do
    before do
      authenticate

      delete :destroy
    end

    it { should redirect_to root_path }
  end
end
