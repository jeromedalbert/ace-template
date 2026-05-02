require_relative 'test_helper'

class RailsNewTest < Minitest::Test
  def setup = base_setup

  def test_rails_new
    output = run_command('./rails-new myapp')

    assert_match(/rails new myapp -m .*template.rb/, output)
    assert_includes output, 'Done!'
    assert_dir 'myapp'
    assert_defaults
  end

  def test_rails_new_from_different_path_than_template
    rails_new_path = File.expand_path('rails-new')
    Dir.chdir('..')

    output = run_command("#{rails_new_path} myapp")

    assert_includes output, 'Done!'
    FileUtils.rm_rf('myapp')
  end

  def test_option_override
    output = run_command('./rails-new myapp --no-skip-jbuilder')

    assert_includes output, 'Done!'
    assert_file 'myapp/Gemfile', 'jbuilder'
  end

  def test_help_option
    output = run_command('./rails-new --help')

    assert_includes output, 'Available options:'
  end

  def test_empty_o_option
    output = run_command('./rails-new -o')

    assert_includes output, 'Available options:'
  end

  def test_missing_app_path
    output = run_command('./rails-new --no-css', capture_errors: true)

    assert_includes output, 'First argument must be the app path'
  end

  def test_worker
    output = run_command('./rails-new myapp -o worker')

    assert_match(/rails new myapp .* --api/, output)
  end

  private

  def assert_defaults
    Dir.chdir('myapp') do
      assert_gemfile 'tailwindcss-rails'
      refute_gemfile 'jbuilder'

      assert_file 'config/application.rb' do |content|
        assert_includes content, '# require "action_mailbox'
        assert_includes content, '# require "action_text'
        assert_includes content, '# require "active_storage'
        assert_includes content, '# require "rails/test_unit'
      end
    end
  end
end
