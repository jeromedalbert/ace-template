setup do
  @user = create(:user)
  authenticate(@user)
end
