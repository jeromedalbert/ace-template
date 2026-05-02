gsub_file 'app/views/layouts/application.html.erb',
          %r{  <body>.*</body>\n}m,
          partial('bootstrap/app/views/layouts/application.html.erb', indent: 2)
template_from 'bootstrap', 'app/views/layouts/_header.html.erb.tt'

copy_file_from 'bootstrap', 'app/views/layouts/_flash_messages.html.erb'
inject_into_module 'app/helpers/application_helper.rb',
                   'ApplicationHelper',
                   partial('bootstrap/app/helpers/application_helper.rb', indent: 2)

copy_file_from 'bootstrap', 'app/views/shared/_base_errors.html.erb'
copy_file_from 'bootstrap', 'config/initializers/field_errors.rb'

template_from 'bootstrap', 'app/views/pages/home.html.erb.tt', force: true
directory_from 'bootstrap', 'app/views/devise' if template_options[:auth] == 'devise'

directory_from 'bootstrap', 'app/assets/stylesheets/base'
directory_from 'bootstrap', 'app/assets/stylesheets/components'
copy_file_from 'bootstrap', 'app/assets/stylesheets/main.scss'
create_file 'app/assets/stylesheets/pages/_index.scss'
append_to_file 'app/assets/stylesheets/application.bootstrap.scss',
               partial('bootstrap/app/assets/stylesheets/application.bootstrap.scss', :prepend_nl)

commit 'Set up Bootstrap'
