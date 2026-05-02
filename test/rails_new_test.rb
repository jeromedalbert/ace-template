require_relative 'test_helper'

class RailsNewTest < Minitest::Test
  def setup = FileUtils.rm_rf('myapp')
  def teardown = setup

  def test_rails_new
    output, status = run_command('./rails-new myapp')

    assert_match(/rails new myapp -m .*template.rb/, output)
    assert_match 'Done!', output
    assert status.success?

    assert_path_exists 'myapp'
    assert_defaults
  end

  def test_option_override
  end

  def test_rails_new_from_different_path_than_template
  end

  def test_help_option
  end

  def test_o_option
  end

  def test_missing_app_path
  end

  def test_worker
  end

  private

  def assert_defaults
    gemfile = File.read('myapp/Gemfile')
    application_config = File.read('myapp/config/application.rb')

    assert_includes gemfile, 'tailwindcss-rails'
    refute_includes gemfile, 'jbuilder'

    assert_includes application_config, '# require "action_mailbox'
    assert_includes application_config, '# require "action_text'
    assert_includes application_config, '# require "active_storage'
    assert_includes application_config, '# require "rails/test_unit'
  end
end
