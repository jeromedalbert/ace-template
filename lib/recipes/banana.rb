module ScaffoldBanana
  def perform
    generate_banana
    configure_banana_model

    if template_options[:auth]
      link_banana_to_user
      set_bananas_as_logged_in_homepage
    else
      set_bananas_as_homepage
    end

    add_banana_to_header
  end

  private

  def generate_banana
    run 'rails generate scaffold Banana name length:integer weight:integer'

    @banana_files = ["$(git ls-files --others '*banana*')", 'config/routes.rb']
  end

  def configure_banana_model
    inject_into_class 'app/models/banana.rb',
                      'Banana',
                      partial('banana/app/models/banana.rb.tt', indent: 2)

    template_from 'banana', 'spec/models/banana_spec.rb.tt', force: true, verbose: false
  end

  def link_banana_to_user
    run 'rails generate migration AddUserToBananas user:belongs_to'
    gsub_file find_file('db/migrate/*_add_user_to_bananas.rb'),
              /add_.*/,
              'add_belongs_to :bananas, :user'

    if template_options[:auth] == 'rails'
      insert_into_file 'app/models/user.rb', "  has_many :bananas\n", after: /has_many.*\n/
    elsif template_options[:auth] == 'devise'
      inject_into_class 'app/models/user.rb', 'User', "  has_many :bananas\n\n"
    end
    @banana_files.push('app/models/user.rb')

    template_from 'banana', 'spec/factories/bananas.rb.tt', force: true

    inject_into_class 'app/controllers/bananas_controller.rb',
                      'BananasController',
                      "  before_action :authenticate\n\n"
    gsub_file 'app/controllers/bananas_controller.rb',
              '@bananas = Banana.all',
              '@bananas = current_user.bananas'
    gsub_file 'app/controllers/bananas_controller.rb',
              '@banana = Banana.new(banana_params)',
              '@banana = Banana.new(banana_params.merge(user: current_user))'
    gsub_file 'app/controllers/bananas_controller.rb',
              '@banana = Banana.find(',
              '@banana = current_user.bananas.find('
    gsub_file 'spec/controllers/bananas_controller_spec.rb',
              /  let\(:banana\) { .*\n/,
              partial('banana/spec/controllers/bananas_controller_spec.rb', indent: 2)

    copy_file_from 'banana', 'app/policies/banana_policy.rb' if template_options[:pundit]
  end

  def set_bananas_as_logged_in_homepage
    if template_options[:auth] == 'rails'
      insert_into_file 'app/controllers/application_controller.rb',
                       "\n  before_action :redirect_root_path\n\n",
                       after: /allow_browser.*\n/
      add_private 'app/controllers/application_controller.rb'
      insert_into_file(
        'app/controllers/application_controller.rb',
        partial('files/banana/app/controllers/application_controller.rb', :prepend_nl, indent: 2),
        before: /^(end|\n  def render_not_authorized.*)/m
      )
    elsif template_options[:auth] == 'devise'
      insert_into_file 'app/controllers/application_controller.rb',
                       "  before_action :redirect_root_path\n\n",
                       after: /before_action .*\n/
      insert_into_file(
        'app/controllers/application_controller.rb',
        partial('files/banana/app/controllers/application_controller.rb', :prepend_nl, indent: 2),
        after: /def set_current_variables\n.*\n. end\n/
      )
    end

    format_code 'app/controllers/application_controller.rb'
    @banana_files << 'app/controllers/application_controller.rb'
  end

  def set_bananas_as_homepage
    gsub_file 'config/routes.rb', /root to: .*/, "root to: 'bananas#index'"
  end

  def add_banana_to_header
    return if !File.exist?('app/views/layouts/_header.html.erb')
    file = File.read('app/views/layouts/_header.html.erb')
    match = file.match(/(?<spaces> *)(?:<!-- )?(?<link><li.*li>)/)
    link = match[:link].sub(/link_to [^,]*, [^, ]*/, "link_to 'Bananas', bananas_path")

    if template_options[:auth]
      insert_into_file 'app/views/layouts/_header.html.erb',
                       "#{match[:spaces]}#{link}\n",
                       before: /.*Log out/
    else
      gsub_file 'app/views/layouts/_header.html.erb', %r{ *<!-- .*}, "#{match[:spaces]}#{link}"
    end

    @banana_files << 'app/views/layouts/_header.html.erb'
  end
end

extend ScaffoldBanana
perform
