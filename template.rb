require 'active_support'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/string'

module Template
  HELP_BANNER = <<~EOS
    ######################
    ### Rails Template ###
    ######################

    Usage:
      rails new APP_PATH -m /path/to/template.rb [-o option1,option2,...] [rails options]

    Template Options:
      active_storage           # Install active storage
      all                      # All options except double, noskip, and worker
      auth[=rails|devise]      # Add authentication
                               # (defaults to rails)
      banana                   # Scaffold an example Banana resource for demo purposes
      dependabot               # Enable GitHub Dependabot
      double                   # Use double-quoted strings
      errors[=rollbar|sentry]  # Add error monitoring service
                               # (defaults to rollbar)
      generators               # Add improved scaffolding generators and templates
      noskip                   # Do not skip Action Mailbox, Action Text, Jbuilder, and Rails' test framework
      omakase                  # active_storage, auth, banana, squash, and vcr options
      pundit                   # Add Pundit authorization
      redis                    # Add Redis
      solid_dev                # Set up Solid adapters for development
      squash                   # Squash all commits into a single "Initial commit"
      vcr                      # Add VCR gem to record test HTTP requests
      worker                   # Removes web code (requires Rails --api option)

    Examples:
      rails new myapp -m /path/to/template.rb
      rails new myapp -m /path/to/template.rb -o banana
      rails new myapp -m /path/to/template.rb -o banana,auth,errors=sentry --css tailwind
  EOS
  REQUIRED_RAILS_VERSIONS = '>= 8.0'
  SUPPORTED_RAILS_VERSIONS = '~> 8.0.0'
  SUPPORTED_RUBY_VERSIONS = '~> 3.3.0'
  SUPPORTED_DATABASES = %w[sqlite3 postgresql mysql]

  def apply_template
    initialize
    configure_gemfile
    check_supported_software
    emit_pre_bundle_message

    after_bundle do
      format_code
      commit
      setup_base_configuration
      configure_dotenv
      configure_database
      configure_rspec
      configure_kamal
      setup_views
      configure_optional_features
      finalize
    end
  end

  private

  def initialize
    apply 'lib/helpers/actions.rb', verbose: false
    apply 'lib/helpers/general.rb', verbose: false
    apply 'lib/helpers/options.rb', verbose: false

    parse_template_options
  end

  def configure_gemfile
    apply 'lib/recipes/gemfile.rb'
  end

  def check_supported_software
    rails_version = Rails.version[/\d+.\d+.\d+/]

    if !compatible_version?(rails_version, REQUIRED_RAILS_VERSIONS)
      emit_required_error(
        required: "Rails #{REQUIRED_RAILS_VERSIONS}",
        current: "Rails #{Rails.version}"
      )
    end
    if !compatible_version?(rails_version, SUPPORTED_RAILS_VERSIONS)
      emit_support_warning(
        supported: "Rails #{SUPPORTED_RAILS_VERSIONS}",
        current: "Rails #{Rails.version}"
      )
    end
    if !compatible_version?(RUBY_VERSION, SUPPORTED_RUBY_VERSIONS)
      emit_support_warning(
        supported: "Ruby #{SUPPORTED_RUBY_VERSIONS}",
        current: "Ruby #{RUBY_VERSION}"
      )
    end

    if !options[:database].in?(SUPPORTED_DATABASES)
      emit_support_warning(supported: SUPPORTED_DATABASES.to_sentence, current: options[:database])
    end
  end

  def compatible_version?(actual_version, version_range)
    Gem::Requirement.new(version_range).satisfied_by?(Gem::Version.new(actual_version))
  end

  def emit_required_error(required:, current:)
    emit_template_error "This template requires #{required}. You are using #{current}."
  end

  def emit_support_warning(supported:, current:)
    emit_warning "This template only officially supports #{supported}. You are using #{current}."
  end

  def emit_pre_bundle_message
    message = "Generating app `#{app_name}`"
    message << " with template options `#{@raw_template_options}`" if @raw_template_options

    emit_info message
  end

  def setup_base_configuration
    apply 'lib/recipes/base_configuration.rb'
  end

  def configure_dotenv
    apply 'lib/recipes/dotenv.rb'
  end

  def configure_database
    apply 'lib/recipes/database.rb' if active_record?
  end

  def configure_rspec
    apply 'lib/recipes/rspec.rb'
  end

  def configure_kamal
    apply 'lib/recipes/kamal.rb' if kamal?
  end

  def setup_views
    apply 'lib/recipes/views.rb' if asset_pipeline?
  end

  def configure_optional_features
    configure_auth if template_options[:auth]
    apply 'lib/recipes/pundit.rb' if template_options[:pundit]

    if asset_pipeline?
      apply 'lib/recipes/tailwind.rb' if options[:css] == 'tailwind'
      apply 'lib/recipes/bootstrap.rb' if options[:css] == 'bootstrap'
    end

    configure_generators
    apply 'lib/recipes/active_storage.rb' if template_options[:active_storage]
    apply 'lib/recipes/errors.rb' if template_options[:errors]
    apply 'lib/recipes/worker.rb' if template_options[:worker]
    apply 'lib/recipes/double_quotes.rb' if template_options[:double]
  end

  def configure_auth
    apply 'lib/recipes/rails_auth.rb' if template_options[:auth] == 'rails'
    apply 'lib/recipes/devise.rb' if template_options[:auth] == 'devise'

    add_before_end 'spec/rails_helper.rb',
                   partial('auth/spec/rails_helper.rb', :prepend_nl, indent: 2)
    copy_file_from 'auth', 'spec/factories/users.rb', force: true
  end

  def configure_generators
    return if !template_options[:generators] && !template_options[:banana]

    apply 'lib/recipes/generators.rb'
    apply 'lib/recipes/banana.rb' if template_options[:banana]

    commit('Set up generators', files: @generator_files.join(' ')) if template_options[:generators]
    commit('Create Banana resource', files: @banana_files.join(' ')) if template_options[:banana]

    if !template_options[:generators]
      run 'git reset HEAD --hard && git clean -fd', capture: true, verbose: false
    end
  end

  def finalize
    FileUtils.cp('.env.sample', '.env') if server_db? && template_options[:solid_dev]
    squash_commits

    if active_record?
      run 'rake db:drop'
      run 'bin/setup --skip-server'
      run 'rails db:migrate'
      commit('Add schema')
      squash_commits
    end

    ENV['DISABLE_SPRING'] = 'false'
    emit_success 'Done! See README.md'
  end

  def squash_commits
    run 'git reset $(git commit-tree HEAD^{tree} -m "Initial commit")' if template_options[:squash]
  end

  def source_paths
    ["#{__dir__}/files/base", "#{__dir__}/files", __dir__] + super
  end
end

extend Template

apply_template
