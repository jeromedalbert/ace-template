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
