private

def user_params
  params.expect(user: %i[email password password_confirmation])
end
