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
    remove_comments 'app/jobs/application_job.rb' if active_job?
    remove_comments 'config/locales/en.yml'
    remove_comments 'config/database.yml' if active_record?
    remove_comments 'config/routes.rb'

    gsub_file '.gitignore', /$^\n^#.*/, ''
    gsub_file '.dockerignore', /$^\n^#.*/, '' if docker?
    gsub_file 'config/routes.rb', /\n\n/, "\n"
    format_quotes(%w[config/locales/en.yml config/queue.yml], style: :single)

    copy_file '.irbrc'
    copy_file '.rubocop.yml', force: true if rubocop?
    copy_file '.streerc'
    template '.ruby-version', force: true

    run 'bundle binstubs syntax_tree'
    cleanup_binstub('stree')
    remove_file 'bin/yarv', verbose: false

    template 'README.md.tt', force: true
    copy_file 'Procfile.dev' if !File.exist?('Procfile.dev')
    if docker?
      gsub_file 'Dockerfile', 'BUNDLE_WITHOUT="development"', 'BUNDLE_WITHOUT="development:test"'
    end

    empty_directory_with_keep_file 'app/services'
  end

  def setup_config_files
    gsub_file 'config/application.rb',
              /^ *#\n *# config.*  end\n/m,
              partial('config/application_end.rb.tt', :prepend_nl, append: "  end\n", indent: 4)

    if template_defaults?
      with_rails_options(skip_action_mailbox: true, skip_action_text: true, skip_test: true) do
        gsub_file 'config/application.rb',
                  /require 'rails(.+\n)*/,
                  %(#{rails_require_statement.tr('"', "'")}\n)
      end
    end

    add_before_end 'config/environments/development.rb',
                   partial('config/environments/development_end.rb', :prepend_nl, indent: 2)

    gsub_file 'config/environments/production.rb',
              '.logger(STDOUT)',
              '.logger(STDOUT, formatter: ->(severity, _, _, msg) { "#{severity} #{msg}\n" })'
    format_code 'config/environments/production.rb'

    copy_file 'config/recurring.yml', force: true if solid?
    copy_file 'config/initializers/lograge.rb'
    copy_file 'config/initializers/redis.rb' if redis?

    apply 'lib/recipes/rails_creds.rb' if template_options[:rails_creds]
    apply 'lib/recipes/solid_dev.rb' if template_options[:solid_dev]
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
    if template_defaults?
      FileUtils.mv '.github/dependabot.yml', '.github/_dependabot.yml'
      insert_into_file '.github/_dependabot.yml',
                       "# Rename this file to dependabot.yml to enable Dependabot updates\n",
                       before: /\A/

      github_ci_content =
        File.read(gem_file('railties', 'lib/rails/generators/rails/app/templates/github/ci.yml.tt'))
      with_rails_options(skip_test: false) do
        github_ci_content = ERB.new(github_ci_content, trim_mode: '-').result(binding)
      end
      File.write '.github/workflows/ci.yml', github_ci_content
    end

    remove_comments '.github/workflows/ci.yml', remove_yml_extra_lines: false
    gsub_file '.github/workflows/ci.yml', /\n+( *(steps|services):)/, "\n\\1"
    gsub_file '.github/workflows/ci.yml', '[ main ]', '[main]'
    gsub_file '.github/workflows/ci.yml', /Scan for common Rails .*/, 'Run Brakeman'
    gsub_file '.github/workflows/ci.yml',
              /Scan for .* JavaScript dependencies/,
              'Audit JavaScript dependencies'
    gsub_file '.github/workflows/ci.yml', /Lint code .*/, 'Run Rubocop' if rubocop?
    insert_into_file '.github/workflows/ci.yml',
                     partial('.github/workflows/ci.yml', :prepend_nl, indent: 6),
                     after: %r{run: bin/rubocop.*\n}

    if File.exist?('config/ci.rb')
      gsub_file 'config/ci.rb', 'Style: Ruby', 'Style: Rubocop' if rubocop?
      insert_into_file(
        'config/ci.rb',
        %(  step 'Style: SyntaxTree', 'bin/stree check $(git ls-files "*.rb" Gemfile Rakefile)'\n),
        after: %r{bin/rubocop.*\n}
      )
    end
  end
end

extend SetupBaseConfiguration
perform
