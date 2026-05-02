require 'test_helper'

module CLI
  class TemplateOptionParserTest < Minitest::Test
    def setup
      @parser = TemplateOptionParser.new(build_app)
    end

    def test_help_option
      @parser = TemplateOptionParser.new(build_app(api: true))

      @app.expects(:show_help).raises(SystemExit)

      assert_raises(SystemExit) { @parser.parse(%w[new myapp -o help]) }
    end

    def test_invalid_app_path
      @parser = TemplateOptionParser.new(build_app('-o'))

      expect_error('First argument must be the app path')

      assert_raises(SystemExit) { @parser.parse(%w[new -o banana]) }
    end

    def test_invalid_option
      expect_error('Invalid template option: foo')

      assert_raises(SystemExit) { @parser.parse(%w[new myapp -o foo]) }
    end

    def test_valid_options
      result = @parser.parse(%w[new myapp -o banana,redis])

      assert_equal({ 'banana' => true, 'redis' => true }, result.template_options)
      assert_equal 'banana,redis', result.selected_options_string
    end

    def test_option_with_default_value
      result = @parser.parse(%w[new myapp -o auth])

      assert_equal({ 'auth' => 'rails' }, result.template_options)
      assert_equal 'auth', result.selected_options_string
    end

    def test_option_with_non_default_value
      result = @parser.parse(%w[new myapp -o auth=devise])

      assert_equal({ 'auth' => 'devise' }, result.template_options)
      assert_equal 'auth=devise', result.selected_options_string
    end

    def test_interactive_option
      CLI::InteractivePrompt.any_instance.stubs(:run).returns('banana' => true, 'auth' => 'rails')

      result = @parser.parse(%w[new myapp -i])

      assert_equal({ 'banana' => true, 'auth' => 'rails' }, result.template_options)
      assert_equal 'banana,auth=rails', result.selected_options_string
    end

    def test_all_option
      result = @parser.parse(%w[new myapp -o all])

      assert_equal(
        {
          'active_storage' => true,
          'auth' => 'rails',
          'banana' => true,
          'dependabot' => true,
          'errors' => 'rollbar',
          'generators' => true,
          'pundit' => true,
          'redis' => true,
          'solid_dev' => true,
          'squash' => true,
          'vcr' => true
        },
        result.template_options
      )
    end

    def test_quick_option
      result = @parser.parse(%w[new myapp -o quick])

      assert_equal(
        {
          'active_storage' => true,
          'auth' => 'rails',
          'banana' => true,
          'squash' => true,
          'vcr' => true
        },
        result.template_options
      )
    end

    def test_worker_option
      @parser = TemplateOptionParser.new(build_app(api: true))

      result = @parser.parse(%w[new myapp --api -o worker])

      assert_equal({ 'solid_dev' => true, 'worker' => true }, result.template_options)
    end

    def test_rails_skip_bundle_option
      @parser = TemplateOptionParser.new(build_app(skip_bundle: true))

      expect_error('This template is incompatible with Rails --skip-bundle option')

      assert_raises(SystemExit) { @parser.parse(%w[new -o banana]) }
    end

    def test_rails_skip_git_option
      @parser = TemplateOptionParser.new(build_app(skip_git: true))

      expect_error('This template is incompatible with Rails --skip-git option')

      assert_raises(SystemExit) { @parser.parse(%w[new -o banana]) }
    end

    def test_solid_dev_option_with_rails_skip_solid_option
      @parser = TemplateOptionParser.new(build_app(skip_solid: true))

      expect_error('solid_dev template option is incompatible with Rails --skip-solid option')

      assert_raises(SystemExit) { @parser.parse(%w[new -o solid_dev]) }
    end

    def test_worker_option_without_api_option
      expect_error('worker template option requires Rails --api option')

      assert_raises(SystemExit) { @parser.parse(%w[new -o worker]) }
    end

    def test_worker_option_with_rails_skip_active_job_option
      @parser = TemplateOptionParser.new(build_app(api: true, skip_active_job: true))

      expect_error('worker template option is incompatible with Rails --skip-active-job option')

      assert_raises(SystemExit) { @parser.parse(%w[new -o worker]) }
    end

    private

    def expect_error(message)
      @parser.expects(:emit_error).with(regexp_matches(/#{message}/)).raises(SystemExit)
    end
  end
end
