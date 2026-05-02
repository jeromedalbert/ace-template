module ControllerSpecHelper
  def render_error
    respond_with :ok
  end
end

RSpec.configure { |c| c.include ControllerSpecHelper, type: :controller }
