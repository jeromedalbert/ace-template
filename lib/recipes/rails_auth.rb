module ConfigureRailsAuth
  def perform
    run 'rails generate authentication'
    # Fix while waiting for https://github.com/thoughtbot/factory_bot_rails/pull/519
    format_code

    configure_authentication_concern
    configure_passwords_controller
    configure_sessions_controller
    configure_user_model
    configure_routes
    configure_other_files

    commit 'Configure Rails authentication'
  end

  private

  def configure_authentication_concern
    gsub_file 'app/controllers/concerns/authentication.rb',
              ':require_authentication',
              ':resume_session'
    session_finding_code = File.read('app/controllers/concerns/authentication.rb')[/Session.find.*/]
    delete_block 'app/controllers/concerns/authentication.rb', '  def find_session_by_cookie'
    gsub_file 'app/controllers/concerns/authentication.rb',
              '= find_session_by_cookie',
              "= #{session_finding_code}"
    gsub_file 'app/controllers/concerns/authentication.rb',
              /^    resume_session$/,
              '    Current.session.present?'
    insert_into_file 'app/controllers/concerns/authentication.rb',
                     "    helper_method :current_user\n",
                     after: /before_action .*\n/

    delete_block 'app/controllers/concerns/authentication.rb', '  class_methods do'
    insert_into_file(
      'app/controllers/concerns/authentication.rb',
      partial('auth/rails_auth/app/controllers/concerns/authentication.rb', :append_nl, indent: 2),
      before: '  def request_authentication'
    )
    move_block 'app/controllers/concerns/authentication.rb',
               '  def authenticated?',
               before: '  def request_authentication'
    move_block 'app/controllers/concerns/authentication.rb',
               '  def require_authentication',
               before: '  def request_authentication'
    insert_blank_line 'app/controllers/concerns/authentication.rb',
                      /session\[:return_to_after_authenticating\] = .*/
    insert_blank_line 'app/controllers/concerns/authentication.rb', 'Current.session.destroy'

    gsub_file 'app/controllers/concerns/authentication.rb', /^    user$/, '    session = user'
    gsub_file 'app/controllers/concerns/authentication.rb',
              ruby_block_regex('      .tap do |session|'),
              "\n\\1"
    format_code 'app/controllers/concerns/authentication.rb'
  end

  def configure_passwords_controller
    split_var_from_condition 'app/controllers/passwords_controller.rb', 'user'
    delete_line 'app/controllers/passwords_controller.rb', '  allow_unauthenticated_access'
    delete_line 'app/controllers/passwords_controller.rb',
                %r{  before_action :set_user_by_token.*\n}

    gsub_file 'app/controllers/passwords_controller.rb', 'set_user_by_token', 'load_user'
    insert_into_file 'app/controllers/passwords_controller.rb',
                     "    load_user\n",
                     after: "def edit\n"
    insert_into_file 'app/controllers/passwords_controller.rb',
                     "    load_user || return\n\n",
                     after: "def update\n"

    insert_into_file 'app/controllers/passwords_controller.rb',
                     "nil\n",
                     after: /redirect_to new_password_path.*\n/
    format_code 'app/controllers/passwords_controller.rb'
  end

  def configure_sessions_controller
    delete_line 'app/controllers/sessions_controller.rb', %r{  allow_unauthenticated_access .*}
    split_var_from_condition 'app/controllers/sessions_controller.rb', 'user'
    gsub_file 'app/controllers/sessions_controller.rb',
              'start_new_session_for user',
              'start_new_session_for(user)'
    gsub_file 'app/controllers/sessions_controller.rb',
              /(terminate_session\n).*/,
              "\\1\n    redirect_to root_path, notice: 'Signed out successfully.'"
  end

  def configure_user_model
    move_line 'app/models/user.rb',
              '  has_secure_password',
              :prepend_nl,
              after: /normalizes :email.*\n/
    insert_into_file 'app/models/user.rb',
                     "  validates :email, presence: true\n",
                     before: '  normalizes :email'

    copy_file_from 'auth/rails_auth', 'spec/models/user_spec.rb', force: true
  end

  def configure_routes
    insert_into_file 'config/routes.rb',
                     partial('auth/rails_auth/config/routes.rb', :prepend_nl, indent: 2),
                     after: /root to: .*\n/

    move_line 'config/routes.rb',
              %r{  resource :session\n  resources :passwords.*},
              :surround_nl,
              after: /root to: .*\n/
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
  end
end

extend ConfigureRailsAuth
perform
