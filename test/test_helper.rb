require 'bundler'
require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'open3'
require 'rails/generators/rails/app/app_generator'
require 'tty-cursor'
require 'tty-reader'

root_path = "#{__dir__}/.."
eval(File.read("#{root_path}/template.rb").gsub("\n\napply_template\n", ''))
Dir["#{root_path}/lib/{cli,helpers}/*.rb"].each { |f| require f }

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]

class Minitest::Test
  def build_app(app_path = 'myapp', **rails_options)
    @app = Rails::Generators::AppGenerator.new([app_path], rails_options)
    @app.stubs(:app_name).returns(app_path)

    @app.extend(Template)
    @app.extend(General)
    @app.extend(Actions)
    @app.extend(Options)

    @app
  end
end
