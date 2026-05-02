require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test 'new' do
    get new_session_path

    assert_response :ok
  end

  test 'create' do
    create(:user, email: 'john@test.com', password: 'abc123')

    post session_path, params: { email: 'john@test.com', password: 'abc123' }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test 'create with invalid credentials' do
    post session_path, params: { email: some_value, password: some_value }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test 'destroy' do
    authenticate

    delete session_path

    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
