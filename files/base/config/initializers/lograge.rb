if Rails.env.production?
  Rails.application.configure do
    config.lograge.enabled = true
    config.lograge.ignore_actions = ['Rails::HealthController#show']
  end
end
