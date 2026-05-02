def redirect_root_path
  redirect_to bananas_path if request.path == '/' && current_user
end
