module SetupViews
  def perform
    define_layout
    add_homepage
    setup_icons

    commit 'Set up views'
  end

  private

  def define_layout
    application_content =
      File.read('app/views/layouts/application.html.erb').sub(
        %r{  <head>\n(.*)  </head>}m,
        "  <head>\n    <%= render partial: 'layouts/head' %>\n  </head>"
      )
    head_content = Regexp.last_match(1).gsub(/^ */, '')

    File.write('app/views/layouts/application.html.erb', application_content)
    File.write('app/views/layouts/_head.html.erb', head_content)

    format_quotes 'app/views/layouts/application.html.erb' if template_options[:double]
  end

  def add_homepage
    insert_into_file 'config/routes.rb',
                     "  root to: 'pages#home'\n\n",
                     after: "Rails.application.routes.draw do\n"

    copy_file 'app/controllers/pages_controller.rb'
    template 'app/views/pages/home.html.erb.tt'
    format_quotes 'app/views/pages/home.html.erb' if template_options[:double]

    if !template_options[:banana] || template_options[:auth]
      add_test_file 'controllers/pages_controller'
    end
  end

  def setup_icons
    return if template_options[:omakase]

    copy_file 'public/icon.png', force: true
    copy_file 'public/icon.svg', force: true

    gsub_file 'app/views/pwa/manifest.json.erb', '"red"', '"#e8e8e8"'
  end
end

extend SetupViews
perform
