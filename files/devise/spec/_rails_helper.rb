config.include Devise::Test::ControllerHelpers, type: :controller

config.before { |example| Current.reset }
config.after { |example| Current.reset }
