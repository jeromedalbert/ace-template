rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized
