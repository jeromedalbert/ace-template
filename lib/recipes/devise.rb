module ConfigureDevise
  def perform
    run 'rails generate devise:install'
    run 'rails generate devise User'

    configure_migration
    configure_user_model
    configure_controllers
    configure_test_helper
    configure_other_files

    commit 'Configure Devise'
  end

  private

  def configure_migration
    migration_file = find_file('db/migrate/*_devise_create_users.rb')

    delete_line migration_file, /^ *##.*\n(^ *#.*\n)+/
    gsub_file migration_file, /.*class/m, 'class'
    gsub_file migration_file, %r{ *# add_index.*. end}m, '  end'
  end

  def configure_user_model
    remove_comments 'app/models/user.rb'
    add_before_end 'app/models/user.rb',
                   partial('auth/devise/app/models/user.rb', :prepend_nl, indent: 2)

    add_test_file 'models/user', from: 'auth/devise'
  end

  def configure_controllers
    add_before_end(
      'app/controllers/application_controller.rb',
      partial('files/auth/devise/app/controllers/application_controller.rb', :prepend_nl, indent: 2)
    )

    if tests?
      insert_into_file controller_test_helper_file_path,
                       partial('auth/devise/tests/helpers/controller_helpers.rb', indent: 2),
                       before: /end\n/
    end
  end

  def configure_test_helper
    return if !tests?

    if rspec?
      add_before_end 'spec/rails_helper.rb', partial('auth/devise/spec/rails_helper.rb', indent: 2)
    else
      test_helper_content = File.read('test/test_helper.rb')
      if test_helper_content.include?('    include ')
        insert_into_file 'test/test_helper.rb',
                         partial('auth/devise/test/test_helper.rb', indent: 4),
                         before: /^    include /
      else
        insert_into_file 'test/test_helper.rb',
                         partial('auth/devise/test/test_helper.rb', :prepend_nl, indent: 4),
                         before: /^  end/
      end
    end
  end

  def configure_other_files
    gsub_file 'config/routes.rb', "  devise_for :users\n", ''
    insert_into_file 'config/routes.rb',
                     partial('auth/devise/config/routes.rb', :prepend_nl, indent: 2),
                     after: /root to: .*\n/

    copy_file_from 'auth/devise', 'app/models/current.rb', force: true
  end
end

extend ConfigureDevise
perform
