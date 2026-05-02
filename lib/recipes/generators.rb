template_from 'generators', 'config/initializers/generators.rb.tt', verbose: false
directory_from 'generators', 'lib/generators', verbose: false
directory_from 'generators', 'lib/templates', verbose: false

gsub_file 'config/application.rb',
          /config.autoload_lib.*/,
          'config.autoload_lib(ignore: %w[assets generators tasks templates])',
          verbose: false
gsub_file '.github/workflows/ci.yml', 'Rakefile)', 'Rakefile | grep -v templates)'

@generator_files = %w[config/initializers lib config/application.rb .github/workflows/ci.yml]
