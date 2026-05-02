def authenticate(user = nil)
  user ||= create(:user)

  Rails.application.reload_routes_unless_loaded
  sign_in user

  user
end
