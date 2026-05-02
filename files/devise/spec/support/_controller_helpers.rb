def authenticate(user = nil)
  user ||= create(:user)

  # Fix while waiting for https://github.com/heartcombo/devise/issues/5694 to be fixed
  Rails.application.try(:reload_routes_unless_loaded)
  sign_in user

  user
end
