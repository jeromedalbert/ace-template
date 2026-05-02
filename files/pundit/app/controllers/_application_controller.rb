rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

private

def render_not_authorized
  redirect_back_or_to(root_path, alert: 'You are not authorized to perform this action.')
end
