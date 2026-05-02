require 'rails_helper'

describe PagesController do
  describe '#home' do
    before { get :home }

    it { should respond_with :ok }
  end
end
