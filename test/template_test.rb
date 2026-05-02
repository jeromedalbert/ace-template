require_relative 'test_helper'

class TemplateTest < Minitest::Test
  def setup = FileUtils.rm_rf('myapp')
  def teardown = setup

  def test_template_main
    output, status = run_rails_new('--main')

    assert_match 'Done!', output
    assert status.success?
  end

  def test_template
    output, status = run_rails_new

    assert_match 'Done!', output
    assert status.success?
  end

  # test default setup result
  # test all options

  private

  def run_rails_new(options = '')
    command = "rails new myapp -m #{File.expand_path('template.rb')}"
    command << " #{options}" if options.present?

    run_command(command)
  end
end
