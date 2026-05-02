require 'test_helper'

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test 'new' do
    get new_registrations_path

    assert_response :ok
  end

  test 'create' do
    post registrations_path, params: { user: { email: some_email, password: some_value } }

    assert_redirected_to root_path
  end

  test 'create with invalid params' do
    post registrations_path, params: { user: { email: '' } }

    assert_response :unprocessable_content
  end
end
