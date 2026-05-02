require 'rails_helper'

describe RegistrationsController do
  describe '#new' do
    before { get :new }

    it { should respond_with :ok }
  end

  describe '#create' do
    context 'when params are valid' do
      before { post :create, params: { user: { email: some_email, password: some_value } } }

      it { should redirect_to root_path }
    end

    context 'when params are invalid' do
      before { post :create, params: { user: { email: '' } } }

      it { should respond_with :unprocessable_content }
    end
  end
end
