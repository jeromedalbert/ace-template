before_action :set_current_variables

def authenticate
  authenticate_user!
end

private

def set_current_variables
  Current.user = current_user
end
