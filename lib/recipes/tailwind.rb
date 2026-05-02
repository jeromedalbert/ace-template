gsub_file 'app/views/layouts/application.html.erb',
          %r{  <body>.*</body>\n}m,
          partial('tailwind/app/views/layouts/application.html.erb', indent: 2)
template_from 'tailwind', 'app/views/layouts/_header.html.erb.tt'

copy_file_from 'tailwind', 'app/views/layouts/_flash_messages.html.erb'
inject_into_module 'app/helpers/application_helper.rb',
                   'ApplicationHelper',
                   partial('tailwind/app/helpers/application_helper.rb', indent: 2)

copy_file_from 'tailwind', 'app/views/shared/_base_errors.html.erb'
copy_file_from 'tailwind', 'config/initializers/field_errors.rb'
insert_into_file 'config/tailwind.config.js',
                 partial('tailwind/config/tailwind.config.js', indent: 2),
                 before: '  theme: {'

template_from 'tailwind', 'app/views/pages/home.html.erb.tt', force: true
directory_from 'tailwind', 'app/views/devise' if template_options[:auth] == 'devise'

commit 'Set up Tailwind'
