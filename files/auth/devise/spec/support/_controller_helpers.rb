def authenticate(user = nil)
  user ||= create(:user)

  sign_in user

  user
end
