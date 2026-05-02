require 'test_helper'

module EndToEnd
  class TemplateTest < EndToEndTest
    def test_template
      output = run_rails_new

      assert_template_done(output)
      assert_default_setup
      assert_app_works
    end

    def test_main_option
      output = run_rails_new('--main')

      assert_template_done(output)
      assert_default_setup
      assert_app_works
    end

    def test_edge_option
      output = run_rails_new('--edge')

      assert_template_done(output)
      assert_default_setup
      assert_app_works
    end

    def test_interactive_option
      output = run_rails_new('-i', keypresses: "jjj \n")

      assert_template_done(output)
      assert_app_works
      assert_banana_option
    end

    def test_invalid_option
      output = run_rails_new('-o foo', capture_errors: true)

      assert_includes output, 'Invalid template option: foo'
      assert_app_deleted
    end

    def test_all_and_tailwind_options
      output = run_rails_new('-o all --css tailwind')

      assert_template_done(output)
      assert_app_works
      assert_active_storage_option
      assert_auth_rails_option
      assert_banana_option
      assert_banana_in_header
      assert_banana_linked_to_user
      assert_css_tailwind_option
      assert_errors_rollbar_option
      assert_generators_option
      assert_pundit_option
      assert_redis_option
      assert_solid_dev_option
      assert_squash_option
      assert_vcr_option
    end

    def test_more_options
      output = run_rails_new('-o auth=devise,double,errors=sentry --css bootstrap')

      assert_template_done(output)
      assert_app_works
      assert_auth_devise_option
      assert_css_bootstrap_option
      assert_double_option
      assert_errors_sentry_option
    end

    def test_worker_option
      output = run_rails_new('-o worker --api')

      assert_template_done(output)
      assert_app_works

      assert_file 'Dockerfile', 'CMD ["bin/jobs"]'
      assert_file 'Procfile.dev', 'worker: bin/jobs'
      assert_file 'bin/dev', 'bin/jobs'
      assert_file 'config/deploy.yml', 'cmd: bin/jobs'
      assert_file 'README.md', 'bin/jobs'

      assert_file 'app/services/say_hello.rb'
      assert_file 'spec/services/say_hello_spec.rb'

      refute_dir 'app/controllers'
      refute_dir 'app/views'
      refute_dir 'public'
      refute_dir 'spec/controllers'

      refute_file 'config.ru'
      refute_file 'config/puma.rb'
      refute_file 'config/routes.rb'

      assert_commit 'Remove web code'
    end

    def test_postgresql_database_option
      postgres_user = ENV['CI'] ? 'postgres' : ENV['USER']
      @env = "DATABASE_URL=postgres://#{postgres_user}@localhost:5432/myapp_development"

      output = run_rails_new('--database postgresql -o banana,solid_dev')

      assert_template_done(output)
      assert_app_works
      assert_banana_option
      assert_solid_dev_option
    end

    def test_mysql_database_option
      @env = 'DATABASE_URL=mysql2://root@127.0.0.1:3306/myapp_development'

      output = run_rails_new('--database mysql -o banana,solid_dev')

      assert_template_done(output)
      assert_app_works
      assert_banana_option
      assert_solid_dev_option
    end

    private

    def assert_template_done(output)
      assert_output('Done!', output)
    end

    def assert_default_setup
      assert_default_gems
      assert_formatted_gemfile
      assert_quote_style :single
      assert_commit 'Initial commit'

      assert_base_config
      assert_dotenv_config
      assert_rspec_config
      assert_kamal_config
      assert_default_views

      assert_file '.env'
      assert_file 'db/schema.rb'
      assert_commit 'Add schema'
    end

    def assert_default_gems
      assert_gemfile 'amazing_print'
      refute_gemfile 'rubocop-rails-omakase'
      refute_gemfile 'tzinfo-data'

      assert_gemfile 'dotenv-rails'
      assert_gemfile 'factory_bot_rails'
      assert_gemfile 'listen'
      assert_gemfile 'rspec-rails'
      assert_gemfile 'rubocop'
      assert_gemfile 'spring'
      assert_gemfile 'spring-watcher-listen'
      assert_gemfile 'standard'
      assert_gemfile 'syntax_tree'

      assert_gemfile 'fuubar'
      assert_gemfile 'rspec-its'
      assert_gemfile 'shoulda-matchers'
      assert_gemfile 'webmock'

      assert_gemfile 'lograge'
    end

    def assert_formatted_gemfile
      refute_gemfile "\n\n\n"
      assert File.read('Gemfile').count('#') <= 2

      assert_gemfile(/kamal.*puma.*rails/m)
      assert_gemfile(/brakeman.*debug/m)
    end

    def assert_quote_style(style)
      if style == :single
        assert_file 'config.ru', "'"
        refute_file 'config.ru', '"'
      elsif style == :double
        assert_file 'config.ru', '"'
        refute_file 'config.ru', "'"
      end
    end

    def assert_base_config
      assert_file '.irbrc'
      assert_file '.streerc'
      assert_file 'README.md', "# My App\n\n## Getting Started"
      assert_file 'Procfile.dev'
      assert_file 'Dockerfile', 'BUNDLE_WITHOUT="development:test"'

      assert_dir 'app/services'
      assert_file 'bin/rspec'
      assert_file 'bin/spring'
      assert_file 'bin/stree'

      assert_file 'config/application.rb', "config.time_zone = ENV['TIMEZONE']"
      assert_file 'config/environments/development.rb', 'config.generators.after_generate'
      assert_file 'config/initializers/lograge.rb'
      assert_file 'config/spring.rb'
      assert_file 'config/storage.yml'

      assert_commit 'Set up base configuration'
    end

    def assert_dotenv_config
      refute_file 'config/credentials.yml.enc'
      refute_file 'config/master.key'

      assert_file '.env.sample' do |content|
        assert_includes content, 'SECRET_KEY_BASE='
        assert_match(/TIMEZONE=.+/, content)
      end

      assert_commit 'Replace Rails credentials with Dotenv'
    end

    def assert_rspec_config
      assert_file '.github/workflows/ci.yml', 'bin/rspec'
      assert_file '.rspec'

      assert_file 'spec/spec_helper.rb'
      assert_file 'spec/rails_helper.rb' do |content|
        assert_includes content, 'webmock'
        assert_includes content, 'TimeHelpers'
        assert_includes content, 'FactoryBot'
      end
      assert_dir 'spec/factories'
      assert_dir 'spec/support'

      assert_commit 'Configure RSpec'
    end

    def assert_kamal_config
      assert_file 'bin/kamal', 'destination =', "require 'dotenv'"

      refute_file '.kamal/secrets'
      assert_file '.kamal/secrets.production' do |content|
        assert_includes content, 'SERVER_IP='
        assert_includes content, 'KAMAL_REGISTRY_USERNAME='
        assert_includes content, 'KAMAL_REGISTRY_PASSWORD='
        assert_includes content, 'SECRET_KEY_BASE='
        assert_match(/TIMEZONE=.+/, content)
      end

      assert_file 'config/deploy.yml' do |content|
        assert_match(/web:\n.*ENV\['SERVER_IP'\]/, content)
        assert_includes content, 'KAMAL_REGISTRY_USERNAME'
        assert_includes content, 'KAMAL_REGISTRY_PASSWORD'
        assert_includes content, '# proxy:'
        assert_match(/secret:\n.*Dotenv.parse/, content)
        refute_includes content, 'clear:'
      end
      assert_file 'config/environments/production.rb', 'assume_ssl = false', 'force_ssl = false'

      assert_commit 'Configure Kamal'
    end

    def assert_default_views
      assert_file 'app/views/layouts/application.html.erb', "render partial: 'layouts/head'"
      assert_file 'app/views/layouts/_head.html.erb'

      assert_file 'config/routes.rb', "root to: 'pages#home'"
      assert_file 'app/controllers/pages_controller.rb'
      assert_file 'spec/controllers/pages_controller_spec.rb'
      assert_file 'app/views/pages/home.html.erb', 'Hello world!'

      assert_commit 'Set up views'
    end

    def assert_app_works
      assert_command_success 'bin/rails boot'
      assert_command_success 'bin/rspec'
      assert_command_success 'bin/rubocop'
      assert_command_success(
        "bin/stree check $(git ls-files '*.rb' Gemfile Rakefile | grep -v templates)"
      )

      secrets = File.read('.kamal/secrets.production').gsub("=\n", "=test\n")
      File.write('.kamal/secrets.production', secrets)
      assert_command_success 'bin/kamal config'
    end

    def assert_banana_option
      assert_file 'app/models/banana.rb', 'validates :name'
      assert_file 'app/controllers/bananas_controller.rb'
      assert_dir 'app/views/bananas'
      assert_file 'config/routes.rb', 'resources :bananas'

      assert_file 'spec/controllers/bananas_controller_spec.rb'
      assert_file 'spec/models/banana_spec.rb'
      assert_file 'spec/factories/bananas.rb'

      assert_equal '0', run_command("bin/rails runner 'puts Banana.count'").strip
    end

    def assert_app_deleted
      refute_equal 'myapp', File.basename(Dir.pwd)
    end

    def assert_active_storage_option
      assert_file Dir['db/migrate/*_create_active_storage_tables*.rb'].first
    end

    def assert_auth_rails_option
      assert_file 'app/models/user.rb', 'validates :email,'
      assert_file 'app/models/current.rb'

      assert_file 'app/controllers/concerns/authentication.rb',
                  'before_action :resume_session',
                  'helper_method :current_user',
                  'alias_method :authenticate'

      assert_file 'app/controllers/sessions_controller.rb'
      refute_file 'app/controllers/sessions_controller.rb', 'allow_unauthenticated_access'
      assert_file 'app/controllers/registrations_controller.rb'

      assert_file 'app/views/sessions/new.html.erb'
      assert_file 'app/views/registrations/new.html.erb'

      assert_file 'app/views/layouts/_header.html.erb', 'Log in', 'Sign up', 'Log out'
      assert_file 'app/views/pages/home.html.erb', /sign up.* to start managing your bananas/m

      assert_file 'config/routes.rb' do |content|
        assert_includes content, 'resource :session'
        assert_includes content, 'resource :registrations'
        assert_match(/get ['"]login/, content)
        assert_match(/get ['"]signup/, content)
        assert_match(/delete ['"]logout/, content)
      end

      assert_file 'spec/models/user_spec.rb'
      assert_file 'spec/factories/users.rb'
      assert_file 'spec/factories/sessions.rb'
      assert_file 'spec/rails_helper.rb', 'Current.reset'
      assert_file 'spec/support/controller_helpers.rb', 'def authenticate'

      assert_equal '0', run_command("bin/rails runner 'puts User.count'").strip
    end

    def assert_banana_in_header
      assert_file 'app/views/layouts/_header.html.erb', "link_to 'Bananas', bananas_path"
    end

    def assert_banana_linked_to_user
      assert_file 'app/models/banana.rb', 'belongs_to :user'
      assert_file 'app/models/user.rb', 'has_many :bananas'
      assert_file 'spec/factories/bananas.rb', 'association :user'

      assert_file 'app/controllers/bananas_controller.rb', 'current_user.bananas'
      assert_file 'app/controllers/application_controller.rb',
                  /redirect_root_path\n.*redirect_to bananas_path/

      assert_file 'app/policies/banana_policy.rb'
    end

    def assert_css_tailwind_option
      assert_file 'app/views/layouts/application.html.erb' do |content|
        assert_match(/<main class=.* mx-auto/, content)
        assert_includes content, "render partial: 'layouts/header'"
        assert_includes content, "render partial: 'layouts/flash_messages'"
      end

      assert_file 'app/views/layouts/_header.html.erb'
      assert_file 'app/views/layouts/_flash_messages.html.erb', 'TAILWIND_ALERT_CLASSES'
      assert_file 'app/helpers/application_helper.rb', 'TAILWIND_ALERT_CLASSES'

      assert_file 'config/initializers/field_errors.rb'
    end

    def assert_errors_rollbar_option
      assert_gemfile 'rollbar'

      assert_file 'config/initializers/rollbar.rb'
      assert_file 'app/jobs/application_job.rb', 'include Rollbar::ActiveJob'
    end

    def assert_generators_option
      assert_file 'config/initializers/generators.rb'

      assert_dir 'lib/generators/rails'
      assert_dir 'lib/templates/rspec'
      assert_dir 'lib/templates/erb/scaffold'

      assert_file 'config/application.rb', /config.autoload_lib\(ignore: .* generators .* templates/
    end

    def assert_pundit_option
      assert_gemfile 'pundit'
      assert_file 'app/policies/application_policy.rb'

      assert_file 'app/controllers/application_controller.rb' do |content|
        assert_includes content, 'include Pundit::Authorization'
        assert_match(/rescue_from .*NotAuthorizedError, with: :render_not_authorized/, content)
        assert_match(/private.*def render_not_authorized/m, content)
      end
    end

    def assert_redis_option
      assert_gemfile 'redis'
      assert_file 'config/initializers/redis.rb'

      assert_command_success "bin/rails runner '$redis.get(1)'"
    end

    def assert_solid_dev_option
      assert_file 'config/cable.yml', "development:\n  <<: *production"
      assert_command_success "bin/rails runner 'ActionCable.server.broadcast(0, { message: 1 })'"

      assert_file 'config/environments/development.rb', ':solid_cache_store'
      assert_command_success "bin/rails runner 'Rails.cache.read(1)'"

      assert_file 'config/environments/development.rb', ':solid_queue'
      assert_equal '0', run_command("bin/rails runner 'puts SolidQueue::Job.count'").strip
    end

    def assert_squash_option
      assert_equal ['Initial commit'], commits
    end

    def assert_vcr_option
      assert_gemfile 'vcr'

      assert_file 'spec/support/vcr.rb'
    end

    def assert_auth_devise_option
      assert_gemfile 'devise'

      assert_file 'app/models/user.rb'
      assert_file 'app/models/current.rb'

      assert_file 'app/controllers/application_controller.rb',
                  'def authenticate',
                  'Current.user = current_user'

      assert_dir 'app/views/devise'
      assert_file 'app/views/layouts/_header.html.erb', 'Log in', 'Sign up', 'Log out'

      assert_file 'config/routes.rb' do |content|
        assert_includes content, 'devise_for :users'
        assert_match(/get ['"]login/, content)
        assert_match(/get ['"]signup/, content)
        assert_match(/delete ['"]logout/, content)
      end

      assert_file 'spec/models/user_spec.rb'
      assert_file 'spec/factories/users.rb'
      assert_file 'spec/rails_helper.rb', 'Current.reset'
      assert_file 'spec/support/controller_helpers.rb', 'def authenticate'

      assert_equal '0', run_command("bin/rails runner 'puts User.count'").strip
    end

    def assert_css_bootstrap_option
      assert_file 'app/views/layouts/application.html.erb' do |content|
        assert_match(%r{render partial: .*layouts/header}, content)
        assert_match(%r{render partial: .*layouts/flash_messages}, content)
        assert_match(/<div class="container"/, content)
      end
      assert_file 'app/views/layouts/_header.html.erb'
      assert_file 'app/views/layouts/_flash_messages.html.erb', 'BOOTSTRAP_ALERT_CLASSES'
      assert_file 'app/helpers/application_helper.rb', 'BOOTSTRAP_ALERT_CLASSES'

      Dir.chdir('app/assets/stylesheets') do
        assert_file 'application.bootstrap.scss' do |content|
          assert_includes content, "@import 'components'"
          assert_includes content, "@import 'main'"
          assert_includes content, "@import 'pages'"
        end
        assert_dir 'components'
        assert_file 'main.scss'
        assert_dir 'pages'
        assert_dir 'base'
      end

      assert_file 'config/initializers/field_errors.rb'
      assert_commit 'Set up Bootstrap'
    end

    def assert_double_option
      assert_quote_style :double

      assert_commit 'Style strings with double quotes'
    end

    def assert_errors_sentry_option
      assert_gemfile 'sentry'
      assert_file 'config/initializers/sentry.rb'

      assert_commit 'Configure Sentry'
    end
  end
end
