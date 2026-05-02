def authenticate(user = nil)
  user ||= build(:user)
  session = create(:session, user: user)

  cookies.signed[:session_id] = session.id

  user
end
