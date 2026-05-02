module SetupBaseConfiguration
  def perform
    setup_base_files
    setup_config_files
    configure_spring
    configure_ci if ci?

    commit 'Set up base configuration'
  end

  private

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

    empty_directory_with_keep_file 'app/services'
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

    setup_solid_dev_config if template_options[:solid_dev]
  end

  def setup_solid_dev_config
    remove_comments 'config/cable.yml'
    delete_line 'config/cable.yml', /development:\n(  .*\n)*/
    gsub_file 'config/cable.yml', 'production:', 'production: &production'
    append_to_file 'config/cable.yml', "\ndevelopment:\n  <<: *production\n"

    gsub_file 'config/environments/development.rb', ':memory_store', ':solid_cache_store'
    gsub_file 'config/cache.yml', /development:\n/, "\\0  database: cache\n"

    insert_into_file(
      'config/environments/development.rb',
      partial('solid_dev/config/environments/development.rb', :append_nl, indent: 2),
      after: /config.active_job.*\n\n/
    )
  end

  def configure_spring
    run 'bundle exec spring binstub --all'
    run 'bundle exec spring stop'
    ENV['DISABLE_SPRING'] = 'true'
    format_code 'bin/*'

    copy_file 'config/spring.rb'
    gsub_file 'config/environments/test.rb', 'enable_reloading = false', 'enable_reloading = true'
  end

  def configure_ci
    github_ci_content =
      URI.parse(
        rails_file('rails', 'railties/lib/rails/generators/rails/app/templates/github/ci.yml.tt')
      ).open
    self.options = options.merge(skip_test: false)
    github_ci_content = ERB.new(github_ci_content.read, trim_mode: '-').result(binding)
    File.write '.github/workflows/ci.yml', github_ci_content

    remove_comments '.github/workflows/ci.yml', remove_yml_extra_lines: false
    gsub_file '.github/workflows/ci.yml', /\n+( *(steps|services):)/, "\n\\1"
    gsub_file '.github/workflows/ci.yml', '[ main ]', '[main]'
    gsub_file '.github/workflows/ci.yml', /Scan for common Rails .*/, 'Run Brakeman'
    gsub_file '.github/workflows/ci.yml',
              /Scan for .* JavaScript dependencies/,
              'Audit JavaScript dependencies'
    gsub_file '.github/workflows/ci.yml', /Lint code .*/, 'Run Rubocop'
    insert_into_file '.github/workflows/ci.yml',
                     partial('.github/workflows/ci.yml', :prepend_nl, indent: 6),
                     after: %r{run: bin/rubocop.*\n}
  end
end

extend SetupBaseConfiguration
perform
