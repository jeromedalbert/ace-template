gsub_file 'app/views/layouts/application.html.erb',
          %r{  <body>.*</body>\n}m,
          partial('tailwind/app/views/layouts/application.html.erb', indent: 2)
template_from 'tailwind', 'app/views/layouts/_header.html.erb.tt'

copy_file_from 'tailwind', 'app/views/layouts/_flash_messages.html.erb'
inject_into_module 'app/helpers/application_helper.rb',
                   'ApplicationHelper',
                   partial('tailwind/app/helpers/application_helper.rb', indent: 2)

copy_file_from 'tailwind', 'lib/templates/erb/scaffold/index.html.erb'

get_rails_file(
  'tailwindcss-rails',
  'lib/generators/tailwindcss/scaffold/templates/show.html.erb.tt',
  'lib/templates/erb/scaffold/show.html.erb'
)
gsub_file 'lib/templates/erb/scaffold/show.html.erb',
          %r{    <div.*button_to "Destroy.*.   </div>\n}m,
          ''
gsub_file 'lib/templates/erb/scaffold/show.html.erb', %r{    <%% if notice.*    <%% end %>\n\n}m, ''

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

copy_file_from 'tailwind', 'app/views/shared/_base_errors.html.erb'
copy_file_from 'tailwind', 'config/initializers/field_errors.rb'
insert_into_file 'config/tailwind.config.js',
                 partial('tailwind/config/tailwind.config.js', indent: 2),
                 before: '  theme: {'

template_from 'tailwind', 'app/views/pages/home.html.erb.tt', force: true
directory_from 'tailwind', 'app/views/devise' if template_options[:auth] == 'devise'

commit 'Set up Tailwind'
