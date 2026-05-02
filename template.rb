require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/string'

module Template
  HELP_BANNER = <<~EOS
    ####################
    ### Ace Template ###
    ####################

    Usage:
      rails new APP_PATH -m /path/to/template.rb [-o option1,option2,...] [-i] [rails options]

    Description:
      Generates a Rails application with curated defaults. For more customization,
      you can provide template options manually with `-o` or interactively with `-i`.

    Template Options:
      active_storage           # Install active storage
      all                      # All options except double, omakase, and worker
      auth[=rails|devise]      # Add authentication
                               # (defaults to rails)
      banana                   # Scaffold an example Banana resource for demo purposes
      double                   # Use double-quoted strings
      errors[=rollbar|sentry]  # Add error monitoring service
                               # (defaults to rollbar)
      generators               # Add improved scaffolding generators and templates
      omakase                  # Use Rails defaults
      pundit                   # Add Pundit authorization
      quick                    # Get started quickly with a basic app (active_storage, auth, banana, squash, and vcr options)
      redis                    # Add Redis
      solid_dev                # Set up Solid adapters for development
      solid_single             # Use a single database for all Solid adapters
      squash                   # Squash all commits into a single "Initial commit"
      vcr                      # Add VCR gem to record test HTTP requests
      worker                   # Removes web code (requires Rails --api option)

    Examples:
      rails new myapp -m /path/to/template.rb
      rails new myapp -m /path/to/template.rb -o banana
      rails new myapp -m /path/to/template.rb -o banana,auth,errors=sentry --css tailwind
      rails new myapp -m /path/to/template.rb -i
  EOS
  REQUIRED_RAILS_VERSIONS = '>= 8.0.1'
  SUPPORTED_RAILS_VERSIONS = ['~> 8.0.0', '~> 8.1.0']
  SUPPORTED_RUBY_VERSIONS = '~> 3.4.0'

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
      prepare_database
      finalize
    end
  end

  private

  def initialize
    set_source_paths
    set_app_created

    apply 'lib/helpers/general.rb', verbose: false
    apply 'lib/helpers/actions.rb', verbose: false
    apply 'lib/helpers/options.rb', verbose: false

    parse_template_options
  end

  def set_source_paths
    base_dir = __dir__

    if __FILE__.match?(%r{^https?://})
      require 'tmpdir'
      base_dir = Dir.mktmpdir('ace-template-')
      at_exit { FileUtils.remove_entry(base_dir) }
      run "git clone https://github.com/jeromedalbert/ace-template #{base_dir}",
          capture: true,
          verbose: false
      branch = __FILE__[%r{ace-template.*/(.+)/template.rb}, 1]
      Dir.chdir(base_dir) { run "git checkout #{branch}", capture: true, verbose: false } if branch
    end

    source_paths.prepend("#{base_dir}/files/base", "#{base_dir}/files", base_dir)
  end

  def set_app_created
    @app_created = Time.now - File.ctime(destination_root) <= 10
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
        supported: "Rails #{SUPPORTED_RAILS_VERSIONS.to_sentence}",
        current: "Rails #{Rails.version}"
      )
    end
    if !compatible_version?(RUBY_VERSION, SUPPORTED_RUBY_VERSIONS)
      emit_support_warning(
        supported: "Ruby #{SUPPORTED_RUBY_VERSIONS}",
        current: "Ruby #{RUBY_VERSION}"
      )
    end
  end

  def compatible_version?(actual_version, version_ranges)
    actual_version = Gem::Version.new(actual_version)

    Array(version_ranges).any? do |version_range|
      Gem::Requirement.new(version_range).satisfied_by?(actual_version)
    end
  end

  def emit_required_error(required:, current:)
    emit_template_error "This template requires #{required}. You are using #{current}."
  end

  def emit_support_warning(supported:, current:)
    emit_warning "This template only officially supports #{supported}. You are using #{current}."
  end

  def emit_pre_bundle_message
    message = "Generating app `#{app_name}`"

    message << " with template options `#{@selected_options_string}`" if @selected_options_string

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
    apply 'lib/recipes/rspec.rb' if tests?
  end

  def configure_kamal
    apply 'lib/recipes/kamal.rb' if kamal?
  end

  def setup_views
    apply 'lib/recipes/views.rb' if !options[:api]
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
    apply 'lib/recipes/solid_single.rb' if template_options[:solid_single]
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

  def prepare_database
    return if !active_record?
    FileUtils.cp('.env.sample', '.env') if server_db? && template_options[:solid_dev]

    output = run('rake db:drop', abort_on_failure: false, capture: true, verbose: false)
    if output.match?(/ConnectionNotEstablished|ConnectionError/)
      emit_warning("Skipped DB preparation (could not connect to #{db} server)")
      return
    else
      say_status :run, 'rake db:drop'
      say output
    end

    run 'bin/setup --skip-server'
    run 'rails db:migrate'
    commit('Add schema')
  end

  def finalize
    squash_commits
    ENV['DISABLE_SPRING'] = 'false'

    emit_success 'Done! See README.md'
  end

  def squash_commits
    run 'git reset $(git commit-tree HEAD^{tree} -m "Initial commit")' if template_options[:squash]
  end

  def apply(path, config = {})
    return super if config[:verbose] == false

    relative_path = path.sub(__dir__, '')
    say_status :apply, relative_path

    shell.padding += 1
    super(path, config.merge(verbose: false))
    shell.padding -= 1
  end
end

extend Template

apply_template
