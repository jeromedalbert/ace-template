module ConfigureErrors
  def perform
    return if !template_options[:errors].in?(%w[rollbar sentry])

    configure_rollbar if template_options[:errors] == 'rollbar'
    configure_sentry if template_options[:errors] == 'sentry'

    commit "Configure #{template_options[:errors].capitalize}"
  end

  private

  def configure_rollbar
    run 'rails generate rollbar'

    remove_comments 'config/initializers/rollbar.rb'
    format_code 'config/initializers/rollbar.rb'

    inject_into_class 'app/jobs/application_job.rb',
                      'ApplicationJob',
                      "  include Rollbar::ActiveJob\n"
  end

  def configure_sentry
    run 'rails generate sentry --no-inject-meta'

    remove_comments 'config/initializers/sentry.rb'
    delete_line 'config/initializers/sentry.rb', /^ *config.enable_tracing.*/
    gsub_file 'config/initializers/sentry.rb',
              '[:active_support_logger]',
              '[:active_support_logger, :http_logger]'
  end
end

extend ConfigureErrors
perform
