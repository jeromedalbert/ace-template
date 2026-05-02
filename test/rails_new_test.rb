require_relative 'test_helper'

class RailsNewTest < Minitest::Test
  def test_rails_new
    output = run_rails_new

    assert_template_output(/rails new .* -m .*template.rb/, output)
    assert_template_done(output)
    assert_defaults
  end

  def test_option_override
    output = run_rails_new('--no-skip-jbuilder')

    assert_template_done(output)
    assert_file 'Gemfile', 'jbuilder'
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
    output = run_rails_new('-o worker')

    assert_template_output(/rails new .* --api/, output)
  end

  private

  def run_rails_new(options = '', capture_errors: false)
    command = './rails-new myapp'
    command << " #{options}" if options.present?

    output = reuse_app? ? nil : run_command(command, capture_errors: capture_errors)

    assert_dir 'myapp'
    Dir.chdir('myapp')
    output
  end

  def assert_defaults
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
