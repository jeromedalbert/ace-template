require 'active_support'
require 'active_support/core_ext/object'
require 'bundler'
require 'minitest/autorun'
require 'minitest/reporters'
require 'open3'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]

def run_command(command)
  Bundler.with_original_env { Open3.capture2(command) }
end
