module SetupGenerators
  def perform
    set_up_generators

    if asset_pipeline?
      set_up_tailwind_templates if options[:css] == 'tailwind'
      set_up_bootstrap_templates if options[:css] == 'bootstrap'
    end
  end

  private

  def set_up_generators
    template_from 'generators', 'config/initializers/generators.rb.tt', verbose: false
    directory_from 'generators', 'lib/generators', verbose: false
    directory_from 'generators', 'lib/templates', verbose: false

    gsub_file 'config/application.rb',
              /config.autoload_lib.*/,
              'config.autoload_lib(ignore: %w[assets generators tasks templates])',
              verbose: false
    gsub_file '.github/workflows/ci.yml', 'Rakefile)', 'Rakefile | grep -v templates)' if ci?

    @generator_files = %w[config/initializers lib config/application.rb .github/workflows/ci.yml]
  end

  def set_up_tailwind_templates
    copy_file_from 'tailwind', 'lib/templates/erb/scaffold/index.html.erb'

    get_rails_file(
      'tailwindcss-rails',
      'lib/generators/tailwindcss/scaffold/templates/show.html.erb.tt',
      'lib/templates/erb/scaffold/show.html.erb'
    )
    gsub_file 'lib/templates/erb/scaffold/show.html.erb',
              %r{  <div.*button_to "Destroy.*  </div>\n}m,
              ''
    gsub_file 'lib/templates/erb/scaffold/show.html.erb', %r{  <%% if notice.*  <%% end %>\n\n}m, ''

    get_rails_file(
      'tailwindcss-rails',
      'lib/generators/tailwindcss/scaffold/templates/_form.html.erb.tt',
      'lib/templates/erb/scaffold/_form.html.erb'
    )
    gsub_file 'lib/templates/erb/scaffold/_form.html.erb', /form_with\((.*)\)/, 'form_with \1'
    gsub_file 'lib/templates/erb/scaffold/_form.html.erb',
              %r{  <%% if.*errors.any.*  <%% end %>\n}m,
              partial('tailwind/lib/templates/erb/scaffold/_form.html.erb', indent: 2)

    get_rails_file(
      'tailwindcss-rails',
      'lib/generators/tailwindcss/scaffold/templates/partial.html.erb.tt',
      'lib/templates/erb/scaffold/partial.html.erb'
    )
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
  end

  def set_up_bootstrap_templates
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/_form.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/edit.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/index.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/new.html.erb'
    copy_file_from 'bootstrap', 'lib/templates/erb/scaffold/show.html.erb'

    get_rails_file(
      'rails',
      'railties/lib/rails/generators/erb/scaffold/templates/partial.html.erb.tt',
      'lib/templates/erb/scaffold/partial.html.erb'
    )
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
  end
end

extend SetupGenerators
perform
