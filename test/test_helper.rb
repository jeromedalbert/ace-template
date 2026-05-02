require 'active_support'
require 'active_support/core_ext/object'
require 'minitest/autorun'
require 'minitest/reporters'
require 'open3'

Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new]

def run_command(command)
  Open3.capture2(command)
end
