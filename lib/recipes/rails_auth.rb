module ConfigureRailsAuth
  def perform
    run 'rails generate authentication', capture: true
    format_code

    configure_authentication_concern
    configure_sessions_controller
    configure_passwords_controller
    configure_user_model
    configure_routes
    configure_views
    configure_other_files

    create_registrations_controller
    create_registrations_view

    commit 'Set up Rails authentication'
  end

  private

  def configure_authentication_concern
    gsub_file 'app/controllers/concerns/authentication.rb',
              ":require_authentication\n",
              ":resume_session\n\n"
    session_finding_code = File.read('app/controllers/concerns/authentication.rb')[/Session.find.*/]
    delete_block 'app/controllers/concerns/authentication.rb',
                 "#{pindent}def find_session_by_cookie"
    gsub_file 'app/controllers/concerns/authentication.rb',
              '= find_session_by_cookie',
              "= #{session_finding_code}"
    gsub_file 'app/controllers/concerns/authentication.rb',
              /^#{pindent}  resume_session$/,
              "#{pindent}  Current.session.present?"
    insert_into_file 'app/controllers/concerns/authentication.rb',
                     "    helper_method :current_user\n",
                     after: /before_action .*\n\n/
    insert_into_file 'app/controllers/concerns/authentication.rb',
                     "\n    alias_method :authenticate, :require_authentication\n",
                     after: /:authenticated\?\n/

    delete_block 'app/controllers/concerns/authentication.rb', '  class_methods do'
    insert_into_file(
      'app/controllers/concerns/authentication.rb',
      partial(
        'auth/rails_auth/app/controllers/concerns/authentication.rb',
        :append_nl,
        indent: pindent.size
      ),
      before: "#{pindent}def request_authentication"
    )
    move_block 'app/controllers/concerns/authentication.rb',
               "#{pindent}def authenticated?",
               before: "#{pindent}def request_authentication"
    move_block 'app/controllers/concerns/authentication.rb',
               "#{pindent}def require_authentication",
               before: "#{pindent}def request_authentication"
    insert_blank_line 'app/controllers/concerns/authentication.rb',
                      /session\[:return_to_after_authenticating\] = .*/
    insert_blank_line 'app/controllers/concerns/authentication.rb', 'Current.session.destroy'

    gsub_file 'app/controllers/concerns/authentication.rb',
              'after_authentication_url',
              'after_authentication_path'
    gsub_file 'app/controllers/concerns/authentication.rb', 'root_url', 'root_path'

    gsub_file 'app/controllers/concerns/authentication.rb', /^    user$/, '    session = user'
    gsub_file 'app/controllers/concerns/authentication.rb',
              ruby_block_regex('      .tap do |session|'),
              "\n\\1"
    format_code 'app/controllers/concerns/authentication.rb'
  end

  def configure_sessions_controller
    delete_line 'app/controllers/sessions_controller.rb', %r{  allow_unauthenticated_access .*}
    gsub_file 'app/controllers/sessions_controller.rb', 'new_session_url', 'new_session_path'

    split_var_from_condition 'app/controllers/sessions_controller.rb', 'user'
    gsub_file 'app/controllers/sessions_controller.rb',
              'start_new_session_for user',
              'start_new_session_for(user)'
    gsub_file 'app/controllers/sessions_controller.rb',
              'redirect_to after_authentication_url',
              "redirect_to after_authentication_path, notice: 'Signed in successfully.'"

    gsub_file 'app/controllers/sessions_controller.rb',
              /(def destroy\n.*)    redirect_to \w*/m,
              "\\1\n    redirect_to root_path, notice: 'Signed out successfully.'"

    add_test_file 'controllers/sessions_controller', from: 'auth/rails_auth'
  end

  def configure_passwords_controller
    split_var_from_condition 'app/controllers/passwords_controller.rb', 'user'
    delete_line 'app/controllers/passwords_controller.rb', '  allow_unauthenticated_access'

    if ace_template_defaults?
      delete_line 'app/controllers/passwords_controller.rb',
                  %r{  before_action :set_user_by_token.*}
      gsub_file 'app/controllers/passwords_controller.rb', 'set_user_by_token', 'load_user'
      insert_into_file 'app/controllers/passwords_controller.rb',
                       "    load_user\n",
                       after: "def edit\n"
      insert_into_file 'app/controllers/passwords_controller.rb',
                       "    load_user || return\n\n",
                       after: "def update\n"
      insert_into_file 'app/controllers/passwords_controller.rb',
                       "nil\n",
                       after: /rescue .*\n *redirect_to new_password_path.*\n/
    end

    format_code 'app/controllers/passwords_controller.rb'

    add_test_file 'controllers/passwords_controller', from: 'auth/rails_auth'
  end

  def configure_user_model
    move_line 'app/models/user.rb',
              '  has_secure_password',
              :prepend_nl,
              after: /normalizes :email.*\n/
    insert_into_file 'app/models/user.rb',
                     partial('auth/rails_auth/app/models/user.rb', :append_nl, indent: 2),
                     before: '  normalizes :email'

    add_test_file 'models/user', from: 'auth/rails_auth'
    add_test_data_file 'users', from: 'auth/tests'
  end

  def configure_routes
    insert_into_file 'config/routes.rb',
                     partial('auth/rails_auth/config/routes.rb', :prepend_nl, indent: 2),
                     after: /root to: .*\n/

    move_line 'config/routes.rb',
              %r{  resource :session\n  resources :passwords.*},
              :surround_nl,
              after: /root to: .*\n/
    insert_into_file 'config/routes.rb', "  resource :registrations\n", after: /resource :session\n/
  end

  def configure_views
    gsub_file 'app/views/sessions/new.html.erb', 'Sign in', 'Log in'
    gsub_file 'app/views/sessions/new.html.erb', 'session_url', 'session_path'

    if options[:css] == 'tailwind'
      remove_flash_messages 'app/views/passwords/edit.html.erb'
      remove_flash_messages 'app/views/passwords/new.html.erb'
      remove_flash_messages 'app/views/sessions/new.html.erb'
    elsif options[:css] == 'bootstrap'
      copy_file_from 'auth/rails_auth/bootstrap', 'app/views/sessions/new.html.erb', force: true
    end
  end

  def remove_flash_messages(file)
    gsub_file file, %r{  <% if alert = .*(^  <h1)}m, '\1'
  end

  def configure_other_files
    if action_cable?
      split_var_from_condition 'app/channels/application_cable/connection.rb', 'session'
      format_code 'app/channels/application_cable/connection.rb'
    end

    auth_files = run('git ls-files --modified --others --exclude-standard', capture: true).split
    auth_files.each { |file| gsub_file(file, /email[_ ]address/, 'email') }
    auth_files.grep(/migrate/).each { |file| gsub_file(file, 't.references', 't.belongs_to') }

    insert_blank_line 'app/controllers/application_controller.rb', 'include Authentication'
    insert_blank_line 'app/mailers/passwords_mailer.rb', '@user = user'
    insert_blank_line 'app/models/current.rb', 'attribute :session'

    return if !tests?
    add_test_data_file 'sessions', from: 'auth/tests'
    if template_options[:rails_tests]
      remove_file 'test/test_helpers/session_test_helper.rb'
      delete_line 'test/test_helper.rb', /require.*session_test_helper.*/
    end
    insert_into_file controller_test_helper_file_path,
                     partial('auth/rails_auth/tests/helpers/controller_helpers.rb.tt', indent: 2),
                     before: /end\n/
  end

  def create_registrations_controller
    FileUtils.cp 'app/controllers/sessions_controller.rb',
                 'app/controllers/registrations_controller.rb'

    gsub_file 'app/controllers/registrations_controller.rb',
              'SessionsController',
              'RegistrationsController'

    gsub_file 'app/controllers/registrations_controller.rb',
              'new_session_path',
              'new_registrations_path'

    insert_into_file 'app/controllers/registrations_controller.rb',
                     "    @user = User.new\n",
                     after: "def new\n"

    gsub_file 'app/controllers/registrations_controller.rb',
              /user = User.authenticate_by.*/,
              '@user = User.new(user_params)'
    gsub_file 'app/controllers/registrations_controller.rb', 'if user', 'if @user.save'
    gsub_file 'app/controllers/registrations_controller.rb',
              'start_new_session_for(user)',
              'start_new_session_for(@user)'
    gsub_file 'app/controllers/registrations_controller.rb',
              'Signed in successfully.',
              'Welcome! You have signed up successfully.'
    gsub_file 'app/controllers/registrations_controller.rb',
              /(^ *)redirect_to new_registrations_path.*/,
              '\1render :new, status: :unprocessable_content'

    gsub_file 'app/controllers/registrations_controller.rb',
              ruby_block_regex('  def destroy'),
              partial('auth/rails_auth/app/controllers/registrations_controller.rb.tt', indent: 2)

    add_test_file 'controllers/registrations_controller', from: 'auth/rails_auth'
  end

  def create_registrations_view
    if options[:css] == 'bootstrap'
      copy_file_from 'auth/rails_auth/bootstrap', 'app/views/registrations/new.html.erb'
      return
    end

    Dir.mkdir 'app/views/registrations'
    FileUtils.cp 'app/views/sessions/new.html.erb', 'app/views/registrations/new.html.erb'

    gsub_file 'app/views/registrations/new.html.erb', 'Log in', 'Sign up'

    gsub_file 'app/views/registrations/new.html.erb',
              /url: session_path/,
              'model: @user, url: registrations_path'
    gsub_file 'app/views/registrations/new.html.erb', 'current-password', 'new-password'
    gsub_file 'app/views/registrations/new.html.erb', 'value: params[:email], ', ''

    password_confirmation_div =
      File.read('app/views/registrations/new.html.erb')[
        %r{( *<div.*\n)?.*password_field.*\n( *</div.*\n\n)?}
      ]
    password_confirmation_div.gsub!(':password', ':password_confirmation')
    password_confirmation_div.gsub!('Enter', 'Repeat')
    insert_into_file 'app/views/registrations/new.html.erb',
                     password_confirmation_div,
                     before: %r{ *(<div class="col-span-6.*|<%= form.submit)}m

    if options[:css] == 'tailwind'
      submit_div =
        File.read('app/views/registrations/new.html.erb')[/ *<div class="inline">\n.*\n.*\n/]
      gsub_file 'app/views/registrations/new.html.erb',
                %r{ *<div class="col-span-6 .*(  <% end %>)}m,
                '\1'
      insert_into_file 'app/views/registrations/new.html.erb',
                       submit_div.gsub(/^  /, ''),
                       before: %r{  <% end %>}
    end
  end
end

extend ConfigureRailsAuth
perform
