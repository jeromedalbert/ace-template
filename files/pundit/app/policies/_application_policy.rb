def user_owns_record?
  return false if user.nil?
  return false if !record.respond_to?(:user_id)

  user.id == record.user_id
end
