def authenticate(user = nil)
  user ||= create(:user)

  # Fix while waiting for https://github.com/heartcombo/devise/issues/5705 to be fixed
  Rails.application.routes_reloader.execute_unless_loaded
  sign_in user

  user
end
