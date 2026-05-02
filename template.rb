require 'active_support'
require 'active_support/core_ext/array/conversions'
require 'active_support/core_ext/string'
require 'bundler'
require 'open3'

# rubocop:disable Style/DisableCopsWithinSourceCodeDirective
# rubocop:disable Lint/InterpolationCheck
# rubocop:disable Style/MixinUsage

module Template
  TEMPLATE_OPTIONS_BANNER = <<~EOS
    Template options:
      -o, [--template-options=option1,option2,...]
          # Available options:
          #
          #   - all: all options except double and worker
          #   - banana: scaffold an example Banana resource for demo purposes
          #   - dependabot: enable GitHub Dependabot
          #   - devise: add Devise authentication
          #   - double: use double-quoted strings
          #   - errors[=rollbar|sentry]: add error monitoring service
          #                              (defaults to rollbar)
          #   - generators: add custom generators for improved scaffolding
          #   - omakase: banana, devise, squash, and vcr options
          #   - pundit: add Pundit authorization
          #   - redis: add Redis
          #   - solid-dev: set up Solid adapters for development
          #   - squash: squash all commits into a single "Initial commit"
          #   - vcr: add VCR gem to record test HTTP requests
          #   - worker: removes web code (requires --api)
  EOS
  REQUIRED_RAILS_VERSIONS = '>= 8.0'
  SUPPORTED_RAILS_VERSIONS = '~> 8.0.0'
  SUPPORTED_RUBY_VERSIONS = '~> 3.3.0'
  SUPPORTED_DATABASES = %w[sqlite3 postgresql mysql]

  def apply_template
    parse_template_options
    configure_gemfile
    check_supported_software

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

  def configure_gemfile
    uncomment_lines 'Gemfile', /gem "image_processing"/ if active_storage?
    remove_comments 'Gemfile'
    gsub_file 'Gemfile', /(^ *(gem|group) .*$)\n\n/, "\\1\n"
    gsub_file 'Gemfile', /(group :development, :test do)/, "\n\\1"

    insert_into_file 'Gemfile',
                     partial('Gemfile_general_gems.rb', :append_nl),
                     before: 'group :development, :test do'
    insert_into_file 'Gemfile',
                     partial('Gemfile_dev_test_gems.rb', indent: 2),
                     after: "group :development, :test do\n"
    append_to_file 'Gemfile', partial('Gemfile_test_gems.rb.tt', :prepend_nl)
    append_to_file 'Gemfile', partial('Gemfile_production_gems.rb', :prepend_nl)

    gsub_file 'Gemfile', %r{  gem "rubocop-rails-omakase".*\n}, ''
    if template_options[:worker]
      delete_line 'Gemfile', /gem "puma".*/
      delete_line 'Gemfile', /gem "thruster".*/
    end

    if !Bundler.current_ruby.windows? && !Bundler.current_ruby.jruby?
      delete_line 'Gemfile', /gem "tzinfo-data".*/
    end
    if Bundler.current_ruby.mri? || Bundler.current_ruby.windows?
      gsub_file 'Gemfile', /(  gem "debug"), platforms: .*,/, '\1,'
    end
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
    emit_critical_error "This template requires #{required}. You are using #{current}."
  end

  def emit_support_warning(supported:, current:)
    emit_warning "This template only officially supports #{supported}. You are using #{current}."
  end

  def format_code(files = '**/*')
    command = ["bundle exec stree write '#{files}'"]
    command += File.read("#{__dir__}/.streerc").split if !File.exist?('.streerc')
    run command.join(' '), capture: true, abort_on_failure: false

    if files == '**/*'
      run 'bundle exec rubocop -A --only Bundler/OrderedGems --config /dev/null', capture: true
    end
  end

  def setup_base_configuration
    setup_base_files
    setup_config_files
    configure_spring
    install_active_storage if active_storage?

    commit 'Set up base configuration'
  end

  def setup_base_files
    remove_comments 'app/controllers/application_controller.rb'
    remove_comments 'app/jobs/application_job.rb'
    remove_comments 'config/locales/en.yml'
    remove_comments 'config/database.yml'
    remove_comments 'config/routes.rb'

    gsub_file '.gitignore', /$^\n^#.*/, ''
    gsub_file 'config/routes.rb', /\n\n/, "\n"
    format_quotes(%w[config/locales/en.yml config/queue.yml], style: :single)

    copy_file '.irbrc'
    copy_file '.rubocop.yml', force: true
    copy_file '.streerc'
    remove_file '.github/dependabot.yml' if !template_options[:dependabot]

    generate_binstub('syntax_tree', 'stree')
    template 'README.md.tt', force: true
    copy_file 'Procfile.dev' if !File.exist?('Procfile.dev')
    gsub_file 'Dockerfile', 'BUNDLE_WITHOUT="development"', 'BUNDLE_WITHOUT="development:test"'

    empty_directory 'app/services'
  end

  def generate_binstub(gem_name, bin_name = gem_name)
    run "bundle binstubs #{gem_name}"

    gsub_file "bin/#{bin_name}", /# (.*\n)*?require/, 'require'
    gsub_file "bin/#{bin_name}", /\n\n/, "\n"
    format_code "bin/#{bin_name}"
  end

  def setup_config_files
    gsub_file 'config/application.rb',
              /^ *#\n *# config.*  end\n/m,
              partial('config/application_end.rb', :prepend_nl, append: "  end\n", indent: 4)

    add_before_end 'config/environments/development.rb',
                   partial('config/environments/development_end.rb', :prepend_nl, indent: 2)

    gsub_file 'config/environments/production.rb',
              '.logger(STDOUT)',
              '.logger(STDOUT, formatter: ->(severity, _, _, msg) { "#{severity} #{msg}\n" })'
    format_code('config/environments/production.rb')

    copy_file 'config/recurring.yml', force: true if solid?
    copy_file 'config/initializers/lograge.rb'
    copy_file 'config/initializers/redis.rb' if redis?

    if template_options[:solid_dev]
      gsub_file 'config/environments/development.rb', ':memory_store', ':solid_cache_store'
      insert_into_file(
        'config/environments/development.rb',
        partial('solid_dev/config/environments/development.rb', :append_nl, indent: 2),
        after: /config.active_job.*\n\n/
      )

      remove_comments 'config/cable.yml'
      delete_line 'config/cable.yml', /development:\n(  .*\n)*/
      gsub_file 'config/cable.yml', 'production:', 'production: &production'
      append_to_file 'config/cable.yml', "\ndevelopment:\n  <<: *production\n"
    end
  end

  def configure_spring
    run 'bundle exec spring binstub --all'
    run 'bundle exec spring stop'
    ENV['DISABLE_SPRING'] = 'true'
    format_code 'bin/*'

    copy_file 'config/spring.rb'
    gsub_file 'config/environments/test.rb', 'enable_reloading = false', 'enable_reloading = true'
  end

  def install_active_storage
    run 'rails active_storage:install'
  end

  def configure_dotenv
    remove_file 'config/credentials.yml.enc'
    remove_file 'config/master.key'

    template '.env.sample.tt'
    insert_into_file '.gitignore', "!/.env.sample\n", after: ".env*\n"
    insert_into_file '.dockerignore', "!/.env.sample\n", after: ".env*\n"

    gsub_file 'bin/setup', /^ *# (.*Copying sample files.*)\n( *# .*\n)*/, <<-EOS
  \\1
  FileUtils.cp '.env.sample', '.env' unless File.exist?('.env')
    EOS
    commit 'Replace Rails credentials with Dotenv'
  end

  def configure_database
    return if skip_active_record?

    if server_db?
      configure_server_db
    elsif sqlite3?
      configure_sqlite
    end
  end

  def configure_server_db
    gsub_file 'config/database.yml',
              /database: #{app_name}_production$/,
              "url: <%= ENV['DATABASE_URL'] %>"
    gsub_file 'config/database.yml',
              /database: #{app_name}_production_(.*)/,
              "url: <%= URI.parse(ENV['DATABASE_URL']).tap { |u| u.path += '_\\1' } if ENV['DATABASE_URL'] %>"
    format_quotes('config/database.yml', style: :single)

    delete_line 'config/database.yml', /^ *username:.*/
    delete_line 'config/database.yml', /^ *password:.*/
    insert_into_file 'config/database.yml', "  username: root\n", after: /pool: .*\n/ if db.mysql?
    configure_solid_dev_db if template_options[:solid_dev]

    commit 'Configure database'
  end

  def configure_solid_dev_db
    database_yml_content =
      File.read('config/database.yml').sub(/(?<=production:\n)(  .*\n)*/, '  <<: *databases')
    databases_config =
      Regexp.last_match(0).remove(' &primary_production').gsub('primary_production', 'default')

    File.write 'config/database.yml', database_yml_content
    insert_into_file 'config/database.yml',
                     "databases: &databases\n#{databases_config}\n",
                     before: 'development:'

    gsub_file 'config/database.yml', /development:\n(  .*\n)*/, "development:\n  <<: *databases\n"
  end

  def configure_sqlite
    return if !template_options[:solid_dev]

    configure_solid_dev_db
    gsub_file 'config/database.yml', %r{(    database: storage/)production}, '\1<%= Rails.env %>'

    commit 'Configure database'
  end

  def configure_rspec
    run 'rails generate rspec:install'
    copy_file '.rspec', force: true
    empty_directory 'spec/factories'
    gsub_file 'config/application.rb',
              /( *g\..*\n)(    end)/,
              '\1' + partial('config/application_rspec.rb', indent: 6) + '\2'

    remove_comments 'spec/spec_helper.rb'
    gsub_file 'spec/spec_helper.rb', %r{=begin\n(.*\n)*=end\n}, ''
    format_code 'spec/spec_helper.rb'

    remove_comments 'spec/rails_helper.rb'
    format_code 'spec/rails_helper.rb'
    gsub_file 'spec/rails_helper.rb', /(^RSpec.configure)/, "\n\\1"
    gsub_file 'spec/rails_helper.rb', /(^  config.*)\n\n/, "\\1\n"
    insert_into_file 'spec/rails_helper.rb',
                     partial('spec/rails_helper_requires.rb.tt', :prepend_nl),
                     after: "require 'rspec/rails'\n"
    add_before_end 'spec/rails_helper.rb',
                   partial('spec/rails_helper_end.rb', :prepend_nl, indent: 2)

    directory 'spec/support'
    copy_file_from 'vcr', 'spec/support/vcr.rb' if template_options[:vcr]

    if ci?
      github_ci_content =
        URI.open 'https://raw.githubusercontent.com/rails/rails/main/railties/lib/rails/generators/rails/app/templates/github/ci.yml.tt'
      self.options = options.merge(skip_test: false)
      github_ci_content = ERB.new(github_ci_content.read, trim_mode: '-').result(binding)
      File.write '.github/workflows/ci.yml', github_ci_content
      remove_comments '.github/workflows/ci.yml', remove_yml_extra_lines: false
      gsub_file '.github/workflows/ci.yml', /\n+( *(steps|services):)/, "\n\\1"
      gsub_file '.github/workflows/ci.yml',
                %r{ *run: bin/rails db:test.*\n},
                partial('spec/.github/workflows/ci.yml', indent: 8)
    end

    commit 'Configure RSpec'
  end

  def configure_kamal
    return if skip_kamal?

    remove_file '.kamal/secrets'
    template '.kamal/secrets.production.tt'
    insert_into_file '.gitignore', ".kamal/secrets*\n", after: ".env.sample\n"
    insert_into_file '.dockerignore', ".kamal/secrets*\n", after: ".env.sample\n"

    insert_into_file 'bin/kamal', partial('bin/kamal.rb', :append_nl), before: 'load Gem.bin_path'
    create_file 'config/deploy.production.yml', "{}\n"

    remove_comments 'config/deploy.yml'
    gsub_file 'config/deploy.yml', "\nimage:", 'image:'
    gsub_file 'config/deploy.yml', /^proxy:\n(  .*\n)*/ do |match|
      match.lines.map { |line| "# #{line}" }.join
    end
    remove_comments 'config/deploy.yml' if template_options[:worker]
    gsub_file 'config/deploy.yml', 'your-user', "<%= ENV['KAMAL_REGISTRY_USERNAME'] %>"
    gsub_file 'config/deploy.yml', /^servers:\n(  .*\n)*/, partial('config/deploy_servers.yml.tt')
    gsub_file 'config/deploy.yml',
              '- RAILS_MASTER_KEY',
              %q(<%= Dotenv.parse(".kamal/secrets.#{ENV['KAMAL_DESTINATION']}").keys - ['KAMAL_REGISTRY_PASSWORD'] %>)
    gsub_file 'config/deploy.yml', %r{ *clear:\n *SOLID_QUEUE_IN_PUMA.*\n$}, ''
    gsub_file 'config/deploy.yml', %r{("bin/rails dbconsole)"}, '\1 --include-password"'
    if !template_options[:worker]
      gsub_file 'config/deploy.yml',
                /(logs: app logs -f)/,
                '\1 --grep-options="--invert-match --extended-regexp" --grep="^[^ ]+ \{"'
    end
    if server_db? || redis?
      append_to_file 'config/deploy.yml', partial('config/deploy_accessories.yml.tt', :prepend_nl)
    end
    append_to_file 'config/deploy.yml', partial('config/deploy_end.yml.tt', :prepend_nl)

    gsub_file 'config/environments/production.rb', 'assume_ssl = true', 'assume_ssl = false'
    gsub_file 'config/environments/production.rb', 'force_ssl = true', 'force_ssl = false'

    template 'db/production.sql.tt' if db.mysql? && solid?

    commit 'Configure Kamal'
  end

  def setup_views
    return if skip_asset_pipeline?
    define_layout
    add_homepage
    setup_icons

    commit 'Set up views'
  end

  def define_layout
    application_content =
      File.read('app/views/layouts/application.html.erb').sub(
        %r{  <head>\n(.*)  </head>}m,
        "  <head>\n    <%= render partial: 'layouts/head' %>\n  </head>"
      )
    head_content = Regexp.last_match(1).gsub(/^ */, '')

    File.write 'app/views/layouts/application.html.erb', application_content
    File.write 'app/views/layouts/_head.html.erb', head_content
  end

  def add_homepage
    insert_into_file 'config/routes.rb',
                     "  root to: 'pages#home'\n\n",
                     after: "Rails.application.routes.draw do\n"

    copy_file 'app/controllers/pages_controller.rb'
    copy_file 'spec/controllers/pages_controller_spec.rb'
    template 'app/views/pages/home.html.erb.tt'
  end

  def setup_icons
    copy_file 'public/icon.png', force: true
    copy_file 'public/icon.svg', force: true

    if File.exist?('app/views/pwa/manifest.json.erb')
      gsub_file 'app/views/pwa/manifest.json.erb', '"red"', '"#e8e8e8"'
    end
  end

  def configure_optional_features
    configure_devise if template_options[:devise]
    configure_pundit if template_options[:pundit]

    if asset_pipeline?
      setup_tailwind if options[:css] == 'tailwind'
      setup_bootstrap if options[:css] == 'bootstrap'
    end

    configure_generators
    configure_errors if template_options[:errors]
    configure_worker if template_options[:worker]

    configure_double_quotes if template_options[:double]
  end

  def configure_devise
    run 'rails generate devise:install'
    run 'rails generate devise User'

    remove_comments 'app/models/user.rb'
    add_before_end 'app/models/user.rb',
                   partial('devise/app/models/user.rb', :prepend_nl, indent: 2)
    remove_file 'spec/models/user_spec.rb'
    copy_file_from 'devise', 'spec/factories/users.rb', force: true
    gsub_file 'config/routes.rb', "  devise_for :users\n", ''
    insert_into_file 'config/routes.rb',
                     partial('devise/config/routes.rb', :prepend_nl, indent: 2),
                     after: /root to: .*\n/

    migration_file = find_file('db/migrate/*_devise_create_users.rb')
    delete_line migration_file, /^ *##.*\n(^ *#.*\n)+/
    gsub_file migration_file, /.*class/m, 'class'
    gsub_file migration_file, %r{ *# add_index.*. end}m, '  end'

    add_before_end(
      'app/controllers/application_controller.rb',
      partial('files/devise/app/controllers/application_controller.rb', :prepend_nl, indent: 2)
    )
    insert_into_file 'spec/support/controller_helpers.rb',
                     partial('devise/spec/support/controller_helpers.rb', indent: 2),
                     before: /end\n/
    add_before_end 'spec/rails_helper.rb', partial('devise/spec/rails_helper.rb', indent: 2)

    commit 'Configure Devise'
  end

  def configure_pundit
    run 'rails g pundit:install'
    insert_into_file 'app/policies/application_policy.rb',
                     partial('pundit/app/policies/application_policy.rb', :append_nl, indent: 2),
                     before: %r{  class Scope}
    gsub_file 'app/policies/application_policy.rb', /\n *private.*. end/m, '  end'
    inject_into_class 'app/policies/application_policy.rb',
                      'Scope',
                      "    attr_reader :user, :scope\n\n"

    inject_into_class 'app/controllers/application_controller.rb',
                      'ApplicationController',
                      "  include Pundit::Authorization\n\n"
    insert_into_file(
      'app/controllers/application_controller.rb',
      partial('pundit/app/controllers/application_controller_middle.rb', :append_nl, indent: 2),
      before: /^(  def authenticate.*|end)/m
    )
    add_before_end(
      'app/controllers/application_controller.rb',
      partial('files/pundit/app/controllers/application_controller_end.rb', :prepend_nl, indent: 2)
    )
    format_code 'app/controllers/application_controller.rb'

    commit 'Configure Pundit'
  end

  def setup_tailwind
    gsub_file 'app/views/layouts/application.html.erb',
              %r{  <body>.*</body>\n}m,
              partial('tailwind/app/views/layouts/application.html.erb', indent: 2)
    template_from 'tailwind', 'app/views/layouts/_header.html.erb.tt'

    copy_file_from 'tailwind', 'app/views/layouts/_flash_messages.html.erb'
    inject_into_module 'app/helpers/application_helper.rb',
                       'ApplicationHelper',
                       partial('tailwind/app/helpers/application_helper.rb', indent: 2)

    copy_file_from 'tailwind', 'lib/templates/erb/scaffold/index.html.erb'

    get 'https://raw.githubusercontent.com/rails/tailwindcss-rails/main/lib/generators/tailwindcss/scaffold/templates/show.html.erb.tt',
        'lib/templates/erb/scaffold/show.html.erb'
    gsub_file 'lib/templates/erb/scaffold/show.html.erb',
              %r{    <div.*button_to "Destroy.*.   </div>\n}m,
              ''
    gsub_file 'lib/templates/erb/scaffold/show.html.erb',
              %r{    <%% if notice.*    <%% end %>\n\n}m,
              ''

    get 'https://raw.githubusercontent.com/rails/tailwindcss-rails/main/lib/generators/tailwindcss/scaffold/templates/_form.html.erb.tt',
        'lib/templates/erb/scaffold/_form.html.erb'
    gsub_file 'lib/templates/erb/scaffold/_form.html.erb',
              %r{  <%% if.*errors.any.*  <%% end %>\n}m,
              partial('tailwind/lib/templates/erb/scaffold/_form.html.erb', indent: 2)

    get 'https://raw.githubusercontent.com/rails/tailwindcss-rails/main/lib/generators/tailwindcss/scaffold/templates/partial.html.erb.tt',
        'lib/templates/erb/scaffold/partial.html.erb'
    gsub_file(
      'lib/templates/erb/scaffold/partial.html.erb',
      /(.*if attribute.attachment\?.*\n).*\n/,
      '\1' + partial('tailwind/lib/templates/erb/scaffold/partial_attachment.html.erb', indent: 4)
    )
    gsub_file(
      'lib/templates/erb/scaffold/partial.html.erb',
      /(.*elsif attribute.attachments\?.*\n.*\n).*\n/,
      '\1' + partial('tailwind/lib/templates/erb/scaffold/partial_attachments.html.erb', indent: 6)
    )

    copy_file_from 'tailwind', 'app/views/shared/_base_errors.html.erb'
    copy_file_from 'tailwind', 'config/initializers/field_errors.rb'
    insert_into_file 'config/tailwind.config.js',
                     partial('tailwind/config/tailwind.config.js', indent: 2),
                     before: '  theme: {'

    template_from 'tailwind', 'app/views/pages/home.html.erb.tt', force: true
    directory_from 'tailwind', 'app/views/devise' if template_options[:devise]

    commit 'Set up Tailwind'
  end

  def setup_bootstrap
    gsub_file 'app/views/layouts/application.html.erb',
              %r{  <body>.*</body>\n}m,
              partial('bootstrap/app/views/layouts/application.html.erb', indent: 2)
    template_from 'bootstrap', 'app/views/layouts/_header.html.erb.tt'

    copy_file_from 'bootstrap', 'app/views/layouts/_flash_messages.html.erb'
    inject_into_module 'app/helpers/application_helper.rb',
                       'ApplicationHelper',
                       partial('bootstrap/app/helpers/application_helper.rb', indent: 2)

    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/_form.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/edit.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/index.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/new.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/show.html.erb'

    get 'https://raw.githubusercontent.com/rails/rails/main/railties/lib/rails/generators/erb/scaffold/templates/partial.html.erb.tt',
        'lib/templates/erb/scaffold/partial.html.erb'
    gsub_file(
      'lib/templates/erb/scaffold/partial.html.erb',
      /(.*if attribute.attachment\?.*\n).*\n/,
      '\1' + partial('bootstrap/lib/templates/erb/scaffold/partial_attachment.html.erb', indent: 4)
    )
    gsub_file(
      'lib/templates/erb/scaffold/partial.html.erb',
      /(.*elsif attribute.attachments\?.*\n.*\n).*\n/,
      '\1' + partial('bootstrap/lib/templates/erb/scaffold/partial_attachments.html.erb', indent: 6)
    )

    copy_file_from 'bootstrap', 'app/views/shared/_base_errors.html.erb'
    copy_file_from 'bootstrap', 'config/initializers/field_errors.rb'

    template_from 'bootstrap', 'app/views/pages/home.html.erb.tt', force: true
    directory_from 'bootstrap', 'app/views/devise' if template_options[:devise]

    directory_from 'bootstrap', 'app/assets/stylesheets/base'
    directory_from 'bootstrap', 'app/assets/stylesheets/components'
    copy_file_from 'bootstrap', 'app/assets/stylesheets/main.scss'
    create_file 'app/assets/stylesheets/pages/_index.scss'
    append_to_file 'app/assets/stylesheets/application.bootstrap.scss',
                   partial(
                     'bootstrap/app/assets/stylesheets/application.bootstrap.scss',
                     :prepend_nl
                   )

    commit 'Set up Bootstrap'
  end

  def configure_generators
    return if !template_options[:generators] && !template_options[:banana]

    add_generators
    scaffold_banana if template_options[:banana]

    commit('Set up generators', files: @generator_files.join(' ')) if template_options[:generators]
    commit('Create Banana resource', files: @banana_files.join(' ')) if template_options[:banana]

    if !template_options[:generators]
      run 'git reset HEAD --hard && git clean -fd', capture: true, verbose: false
    end
  end

  def add_generators
    gsub_file 'config/application.rb',
              /config.autoload_lib.*/,
              'config.autoload_lib(ignore: %w[assets generators tasks templates])',
              verbose: false

    template_from 'generators', 'config/initializers/generators.rb.tt', verbose: false
    directory_from 'generators', 'lib/generators', verbose: false
    directory_from 'generators', 'lib/templates', verbose: false

    @generator_files = %w[config/application.rb config/initializers lib]
  end

  def scaffold_banana
    run 'rails generate scaffold Banana name length:integer weight:integer'
    @banana_files = ["$(git ls-files --others '*banana*')", 'config/routes.rb']

    inject_into_class 'app/models/banana.rb',
                      'Banana',
                      partial('banana/app/models/banana.rb.tt', indent: 2)
    template_from 'banana', 'spec/models/banana_spec.rb.tt', force: true, verbose: false

    if template_options[:devise]
      link_banana_to_user
    else
      gsub_file 'config/routes.rb', /root to: .*/, "root to: 'bananas#index'"
    end

    return if !File.exist?('app/views/layouts/_header.html.erb')
    file = File.read('app/views/layouts/_header.html.erb')
    match = file.match(/(?<spaces> *)(?:<!-- )?(?<link><li.*li>)/)
    link = match[:link].sub(/link_to [^,]*, [^, ]*/, "link_to 'Bananas', bananas_path")

    if template_options[:devise]
      insert_into_file 'app/views/layouts/_header.html.erb',
                       "#{match[:spaces]}#{link}\n",
                       before: /.*Log out/
    else
      gsub_file 'app/views/layouts/_header.html.erb', %r{ *<!-- .*}, "#{match[:spaces]}#{link}"
    end
    @banana_files << 'app/views/layouts/_header.html.erb'
  end

  def link_banana_to_user
    run 'rails generate migration AddUserToBananas user:belongs_to'
    gsub_file find_file('db/migrate/*_add_user_to_bananas.rb'),
              /add_.*/,
              'add_belongs_to :bananas, :user'

    inject_into_class 'app/models/user.rb',
                      'User',
                      partial('banana/app/models/user.rb', :append_nl, indent: 2)
    copy_file_from 'banana', 'spec/models/user_spec.rb'
    @banana_files.push('app/models/user.rb', 'spec/models/user_spec.rb')

    inject_into_class 'app/controllers/bananas_controller.rb',
                      'BananasController',
                      "  before_action :authenticate\n\n"
    gsub_file 'app/controllers/bananas_controller.rb',
              '@bananas = Banana.all',
              '@bananas = current_user.bananas'
    gsub_file 'app/controllers/bananas_controller.rb',
              '@banana = Banana.new(banana_params)',
              '@banana = Banana.new(banana_params.merge(user: current_user))'
    gsub_file 'app/controllers/bananas_controller.rb',
              '@banana = Banana.find(',
              '@banana = current_user.bananas.find('
    gsub_file 'spec/controllers/bananas_controller_spec.rb',
              /  let\(:banana\) { .*\n/,
              partial('banana/spec/controllers/bananas_controller_spec.rb', indent: 2)

    insert_into_file 'app/controllers/application_controller.rb',
                     "\n  before_action :redirect_root_path\n\n",
                     before: %r{  rescue_from.*|  def authenticate}m
    if !File.read('app/controllers/application_controller.rb').match?(/^  private/)
      add_before_end 'app/controllers/application_controller.rb', "  private\n"
    end
    insert_into_file(
      'app/controllers/application_controller.rb',
      partial('files/banana/app/controllers/application_controller.rb', :prepend_nl, indent: 2),
      after: /^  private\n/
    )
    format_code('app/controllers/application_controller.rb')
    @banana_files << 'app/controllers/application_controller.rb'

    copy_file_from 'banana', 'app/policies/banana_policy.rb' if template_options[:pundit]
  end

  def configure_errors
    case template_options[:errors]
    when 'rollbar'
      run 'rails generate rollbar'
      remove_comments 'config/initializers/rollbar.rb'
      format_code 'config/initializers/rollbar.rb'
      inject_into_class 'app/jobs/application_job.rb',
                        'ApplicationJob',
                        "  include Rollbar::ActiveJob\n"
    when 'sentry'
      run 'rails generate sentry --no-inject-meta'
      remove_comments 'config/initializers/sentry.rb'
      delete_line 'config/initializers/sentry.rb', /^ *config.enable_tracing.*/
      gsub_file 'config/initializers/sentry.rb',
                '[:active_support_logger]',
                '[:active_support_logger, :http_logger]'
    end
  end

  def configure_worker
    create_file 'config/routes.rb', "\n", force: true
    remove_dir 'app/controllers'
    remove_dir 'app/views'
    remove_dir 'public'
    remove_dir 'spec/controllers'

    remove_file 'config.ru'
    remove_file 'config/puma.rb'
    remove_file 'config/initializers/cors.rb'
    remove_file 'spec/support/controller_helpers.rb'

    comment_lines 'config/application.rb', "require 'action_controller/railtie'"

    File.write 'Procfile.dev', "worker: bin/jobs\n"
    gsub_file 'bin/dev', /exec .*/, "exec 'bin/jobs', *ARGV"
    gsub_file 'Dockerfile', /# Start server.*/, '# Start background jobs'
    gsub_file 'Dockerfile', /EXPOSE .*\nCMD .*/, 'CMD ["bin/jobs"]'
    gsub_file 'bin/docker-entrypoint', 'running the rails server', 'processing jobs'
    gsub_file 'bin/docker-entrypoint', %r{if .*bin/rails.*then}, 'if [ $1 == "bin/jobs" ]; then'

    copy_file_from 'worker', 'app/services/say_hello.rb'
    copy_file_from 'worker', 'spec/services/say_hello_spec.rb'

    commit 'Remove web code'
  end

  def configure_double_quotes
    gsub_file '.streerc', 'plugin/single_quotes,', ''
    delete_line '.rubocop.yml', %r{Style/StringLiterals.*\n  .*}

    format_code
    format_quotes(
      %w[
        .irbrc
        .rubocop.yml
        config/database.yml
        config/locales/en.yml
        config/queue.yml
        app/views/layouts/*.html.erb
        lib/templates/erb/scaffold/*.html.erb
      ],
      style: :double
    )

    commit 'Style strings with double quotes'
  end

  def finalize
    FileUtils.cp('.env.sample', '.env') if server_db? && template_options[:solid_dev]
    run 'rake db:drop'
    run 'bin/setup --skip-server'
    run 'rails db:migrate' # Doing this while waiting for a potential fix on Rails main
    commit('Add schema')

    run 'git reset $(git commit-tree HEAD^{tree} -m "Initial commit")' if template_options[:squash]

    ENV['DISABLE_SPRING'] = 'false'
    emit_success 'Done! See README.md'
  end
end

module TemplateHelpers
  attr_accessor :template_options

  def parse_template_options
    @template_options = {}
    raw_options = Thor::Options.new(_: Thor::Option.new(:template_options, { aliases: '-o' }))
    raw_options = raw_options.parse(ARGV)['template_options']
    return if raw_options.nil? || raw_options == 'template_options'
    allowed_options = Template::TEMPLATE_OPTIONS_BANNER.scan(/- ([a-z-]*).*:/).flatten

    raw_options
      .split(',')
      .each do |option|
        option_key, option_value = option.split('=')
        if !option_key.in?(allowed_options)
          emit_critical_error("Invalid template option: #{option_key}")
        end
        @template_options[option_key.underscore.to_sym] = option_value || true
      end

    if @template_options[:all]
      @template_options.merge!(
        dependabot: true,
        errors: true,
        generators: true,
        omakase: true,
        pundit: true,
        redis: true
      )
    end
    if @template_options[:omakase]
      @template_options.merge!(banana: true, devise: true, squash: true, vcr: true)
    end
    @template_options[:solid_dev] = true if @template_options[:worker] && solid?
    set_multi_option_default(:errors, 'rollbar')

    if @template_options[:worker] && !options[:api]
      emit_critical_error 'worker template option requires Rails --api option'
    end
    if @template_options[:solid_dev]
      if skip_solid?
        emit_critical_error 'solid-dev template option is incompatible with Rails --skip-solid option'
      elsif !options[:database].in?(Template::SUPPORTED_DATABASES)
        emit_critical_error 'solid-dev template option currently only works for ' \
                              "#{Template::SUPPORTED_DATABASES.to_sentence}."
      end
    end
  end

  def set_multi_option_default(option, default)
    if @template_options.key?(option) && !@template_options[option].is_a?(String)
      @template_options[option] = default
    end
  end

  def db
    options[:database].inquiry
  end

  def server_db?
    !skip_active_record? && !sqlite3?
  end

  def redis?
    @has_redis ||= File.read('Gemfile').include?('redis')
  end

  def active_storage?
    !skip_active_storage?
  end

  def action_cable?
    !skip_action_cable?
  end

  def asset_pipeline?
    !skip_asset_pipeline?
  end

  def ci?
    !skip_ci?
  end

  def solid?
    !skip_solid?
  end

  def partial(file_path, *nl_opts, **opts)
    prepend = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:prepend_nl)
    prepend ||= opts[:surround] || opts[:prepend]
    append = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:append_nl)
    append ||= opts[:surround] || opts[:append]
    indent = opts[:indent] || 0

    file_path =
      file_path
        .split('/')
        .tap { |components| components[-1] = "_#{components[-1]}" }
        .join('/')
        .then { |path| find_in_source_paths(path) }

    file_content = File.read(file_path)
    if file_path.end_with?('.tt')
      file_content = ERB.new(file_content, trim_mode: '-').result(binding)
    end

    prepend.to_s + indent(file_content, indent) + append.to_s
  end

  def commit(message = 'Initial commit', files: '--all')
    if `git status --porcelain`.empty?
      emit_critical_error %(Cannot commit with message "#{message}": there are no files to commit.)
    end

    run "git add #{files}"
    run "git commit -m '#{message}'", capture: true
  end

  def remove_comments(file, remove_yml_extra_lines: true)
    delete_line file, /^ *#.*/

    gsub_file file, /\n{3,}/, "\n\n"
    if File.extname(file) == '.yml' && remove_yml_extra_lines
      gsub_file file, /\n{2,}(  .*)/, "\n\\1"
    end

    gsub_file file, /\A\n+/, ''
    gsub_file file, /^\n+\z/, ''
    gsub_file file, /\n\nend/, "\nend"
  end

  def run(command, config = {})
    abort_on_failure = config.fetch(:abort_on_failure, true)
    return super if !abort_on_failure || !config[:capture]
    destination = relative_to_original_destination_root(destination_root, false)
    say_status :run, "#{command} from #{destination.inspect}", config.fetch(:verbose, true)

    result, status = Open3.capture2e(command.to_s)

    status.success? ? result : emit_critical_error(result)
  end

  def copy_file_from(folder, file_path, ...)
    copy_file("#{folder}/#{file_path}", file_path, ...)
  end

  def directory_from(folder, dir_path, ...)
    directory("#{folder}/#{dir_path}", dir_path, ...)
  end

  def template_from(folder, file_path, ...)
    template("#{folder}/#{file_path}", file_path.chomp('.tt'), ...)
  end

  def add_before_end(file_path, content)
    insert_into_file file_path, content, before: /^end\n\z/
  end

  def delete_line(file_path, line_regex)
    gsub_file file_path, /^#{line_regex}\n/, ''
  end

  def format_quotes(files, style:)
    from, to =
      if style == :single
        %w[" ']
      elsif style == :double
        %w[' "]
      end

    Dir[*files].each { |file| gsub_file file, from, to }
  end

  def timezone
    @timezone ||= run('rake time:zones:local', verbose: false, capture: true).split("\n")[2]
  end

  def app_title
    app_name.sub(/([^[:punct:]])app$/, '\1 app').titleize
  end

  def app_uniqueish_name
    delimiter = app_name[/[_-]/]
    unprefixed_name = app_name.remove(/^(my|cool|great|amazing)#{delimiter}?/)
    stripped_name = unprefixed_name.parameterize.remove('-', /app$/)

    if stripped_name.in?(['', 'test', 'sample', 'blog', 'project'])
      "#{Etc.getlogin}#{delimiter}#{unprefixed_name}"
    else
      app_name
    end
  end

  def emit_warning(message)
    say("\n[WARNING] #{message}\n\n", :yellow)
  end

  def emit_critical_error(message)
    say("\n[ERROR] #{message}\nApp generation aborted.\n\n", :red)
    abort
  end

  def emit_success(message)
    say("\n#{message}\n\n", :green)
  end

  def find_file(pattern)
    Dir[pattern].first
  end

  def source_paths
    [__dir__, "#{__dir__}/files/base", "#{__dir__}/files"] + super
  end
end

extend Template
extend TemplateHelpers

apply_template if !$PROGRAM_NAME.end_with?('rails-new')

# rubocop:enable all
