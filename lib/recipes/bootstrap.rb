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
