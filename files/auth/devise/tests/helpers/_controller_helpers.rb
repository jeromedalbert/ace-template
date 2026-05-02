def authenticate(user = nil)
  user ||= create(:user)

  sign_in user

  user
end

def unauthenticate
  sign_out :user
end
