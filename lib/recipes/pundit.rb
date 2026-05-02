run 'rails g pundit:install'

insert_into_file 'app/policies/application_policy.rb',
                 partial('pundit/app/policies/application_policy.rb', :append_nl, indent: 2),
                 before: %r{  class Scope}
gsub_file 'app/policies/application_policy.rb', /\n *private.*. end/m, '  end'
inject_into_class 'app/policies/application_policy.rb', 'Scope', "    attr_reader :user, :scope\n\n"

inject_into_class 'app/controllers/application_controller.rb',
                  'ApplicationController',
                  "  include Pundit::Authorization\n\n"
insert_into_file(
  'app/controllers/application_controller.rb',
  "  rescue_from Pundit::NotAuthorizedError, with: :render_not_authorized\n\n",
  before: /^(  def authenticate.*|end)/m
)
add_private 'app/controllers/application_controller.rb'
add_before_end(
  'app/controllers/application_controller.rb',
  partial('files/pundit/app/controllers/application_controller_end.rb', :prepend_nl, indent: 2)
)
format_code 'app/controllers/application_controller.rb'

commit 'Configure Pundit'
