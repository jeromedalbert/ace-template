run 'rails generate devise:install'
run 'rails generate devise User'

remove_comments 'app/models/user.rb'
add_before_end 'app/models/user.rb',
               partial('auth/devise/app/models/user.rb', :prepend_nl, indent: 2)
remove_file 'spec/models/user_spec.rb'
copy_file_from 'auth/devise', 'spec/factories/users.rb', force: true
gsub_file 'config/routes.rb', "  devise_for :users\n", ''
insert_into_file 'config/routes.rb',
                 partial('auth/devise/config/routes.rb', :prepend_nl, indent: 2),
                 after: /root to: .*\n/
copy_file_from 'auth/devise', 'app/models/current.rb', force: true

migration_file = find_file('db/migrate/*_devise_create_users.rb')
delete_line migration_file, /^ *##.*\n(^ *#.*\n)+/
gsub_file migration_file, /.*class/m, 'class'
gsub_file migration_file, %r{ *# add_index.*. end}m, '  end'

add_before_end(
  'app/controllers/application_controller.rb',
  partial('files/auth/devise/app/controllers/application_controller.rb', :prepend_nl, indent: 2)
)
insert_into_file 'spec/support/controller_helpers.rb',
                 partial('auth/devise/spec/support/controller_helpers.rb', indent: 2),
                 before: /end\n/
add_before_end 'spec/rails_helper.rb', partial('auth/devise/spec/rails_helper.rb', indent: 2)

commit 'Configure Devise'
