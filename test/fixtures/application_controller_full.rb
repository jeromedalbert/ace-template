class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :redirect_root_path

  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized

  private

  def redirect_root_path
    redirect_to bananas_path if request.path == '/' && current_user
  end

  def render_not_authorized
    redirect_back_or_to(root_path, alert: 'You are not authorized to perform this action.')
  end
end
