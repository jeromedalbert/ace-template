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

    File.write 'app/views/layouts/application.html.erb', application_content
    File.write 'app/views/layouts/_head.html.erb', head_content
  end

  def add_homepage
    insert_into_file 'config/routes.rb',
                     "  root to: 'pages#home'\n\n",
                     after: "Rails.application.routes.draw do\n"

    copy_file 'app/controllers/pages_controller.rb'
    template 'app/views/pages/home.html.erb.tt'

    if !template_options[:banana] || template_options[:auth]
      copy_file 'spec/controllers/pages_controller_spec.rb'
    end
  end

  def setup_icons
    copy_file 'public/icon.png', force: true
    copy_file 'public/icon.svg', force: true

    if File.exist?('app/views/pwa/manifest.json.erb')
      gsub_file 'app/views/pwa/manifest.json.erb', '"red"', '"#e8e8e8"'
    end
  end
end

extend SetupViews
perform
