module ControllerTestHelper
end

ActiveSupport.on_load(:action_dispatch_integration_test) { include ControllerTestHelper }
