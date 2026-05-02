require 'test_helper'

class TemplateTest < Minitest::Test
  def test_template
    @template = build_template('myapp')

    expect_output('Generating app `myapp`')
    expect_output('Done!')

    @template.apply_template
  end

  def test_template_options
    @template = build_template
    @template.instance_variable_set(:@selected_options_string, 'banana,auth=devise')

    expect_output('Generating app `myapp` with template options `banana,auth=devise`')
    expect_output('Done!')

    @template.apply_template
  end

  def test_incompatible_rails_version
    @template = build_template
    Rails.stubs(:version).returns('7.2.0')

    expect_error(/This template requires Rails .*/)

    @template.apply_template
  end

  def test_unsupported_rails_version
    @template = build_template
    Rails.stubs(:version).returns('100.0.0.beta1')

    expect_warning(/This template only officially supports Rails .*/)

    @template.apply_template
  end

  def test_bad_database_connection
    @template = build_template
    @template.stubs(:run).with('rake db:drop', anything).returns('ConnectionNotEstablished')

    expect_warning(/Skipped DB preparation \(could not connect/)

    @template.apply_template
  end

  private

  def build_template(app_path = 'myapp', **rails_options)
    template = build_app(app_path, **rails_options)
    template.instance_variable_set(:@template_options, {})

    template.stubs(:apply)
    template.stubs(:run).returns('')
    template.stubs(:parse_template_options)
    template.stubs(:after_bundle).yields
    template.stubs(:find_in_source_paths).returns('')
    template.stubs(:commit)
    if !ENV['LOG_TO_STDOUT']
      template.stubs(:say)
      template.stubs(:say_status)
    end

    template
  end

  def expect_output(message)
    @template.expects(:say).with(regexp_matches(/#{message}/), anything)
  end

  def expect_error(message)
    @template.expects(:emit_template_error).with(regexp_matches(/#{message}/))
  end

  def expect_warning(message)
    @template.expects(:emit_warning).with(regexp_matches(/#{message}/))
  end
end
