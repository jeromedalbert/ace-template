gsub_file 'app/views/layouts/application.html.erb',
          %r{  <body>.*</body>\n}m,
          partial('tailwind/app/views/layouts/application.html.erb', indent: 2)
format_quotes 'app/views/layouts/application.html.erb' if template_options[:double]

template_from 'tailwind', 'app/views/layouts/_header.html.erb.tt'
format_quotes 'app/views/layouts/_header.html.erb' if template_options[:double]

copy_file_from 'tailwind', 'app/views/layouts/_flash_messages.html.erb'
inject_into_module 'app/helpers/application_helper.rb',
                   'ApplicationHelper',
                   partial('tailwind/app/helpers/application_helper.rb', indent: 2)

copy_file_from 'tailwind', 'app/views/shared/_base_errors.html.erb'
copy_file_from 'tailwind', 'config/initializers/field_errors.rb'

template_from 'tailwind', 'app/views/pages/home.html.erb.tt', force: true
format_quotes 'app/views/pages/home.html.erb' if template_options[:double]

directory_from 'tailwind', 'app/views/devise' if template_options[:auth] == 'devise'
format_quotes 'app/views/devise/**/*.html.erb' if template_options[:double]

commit 'Set up Tailwind'
