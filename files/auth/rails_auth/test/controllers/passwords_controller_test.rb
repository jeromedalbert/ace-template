require 'test_helper'

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test 'new' do
    get new_password_path

    assert_response :ok
  end

  test 'create' do
    create(:user, email: 'john@test.com')
    PasswordsMailer.expects(:reset).returns(stub_everything)

    post passwords_path, params: { email: 'john@test.com' }

    assert_redirected_to new_session_path
  end

  test 'create with nonexistent email' do
    PasswordsMailer.expects(:reset).never

    post passwords_path, params: { email: some_email }

    assert_redirected_to new_session_path
  end

  test 'edit' do
    user = create(:user)

    get edit_password_path(user.password_reset_token)

    assert_response :ok
  end

  test 'edit with invalid token' do
    get edit_password_path('invalid_token')

    assert_redirected_to new_password_path
  end

  test 'update' do
    user = create(:user)

    patch password_path(user.password_reset_token),
          params: {
            password: 'abc123',
            password_confirmation: 'abc123'
          }

    assert_redirected_to new_session_path
  end

  test 'update with non matching passwords' do
    user = create(:user)

    patch password_path(user.password_reset_token),
          params: {
            password: 'abc123',
            password_confirmation: 'def456'
          }

    assert_redirected_to edit_password_path
  end

  test 'update with invalid token' do
    patch password_path('invalid_token')

    assert_redirected_to new_password_path
  end
end
