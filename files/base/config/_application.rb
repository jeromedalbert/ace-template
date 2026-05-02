config.time_zone = ENV['TIMEZONE']

config.action_controller.include_all_helpers = false

config.generators { |g| g.helper false }
