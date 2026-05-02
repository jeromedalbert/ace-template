require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'home' do
    get root_path

    assert_response :ok
  end
end
