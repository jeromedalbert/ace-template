require 'bundler'
require 'minitest/autorun'
require 'minitest/reporters'
require 'mocha/minitest'
require 'open3'
require 'rails/generators/rails/app/app_generator'
require 'tty-cursor'
require 'tty-reader'

def root_path = "#{__dir__}/.."
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

class EndToEndTest < Minitest::Test
  def setup
    Dir.chdir(root_path)

    FileUtils.rm_rf('tmp/myapp') if !ENV['REUSE_APP']

    @commits = nil
    @env = nil
  end

  def run_command(command, capture_errors: false, keypresses: nil)
    method = capture_errors ? :capture2e : :capture2
    command = "#{@env} #{command}" if @env

    output, status =
      Bundler.with_original_env { Open3.send(method, command, stdin_data: keypresses) }
    raise_failed(command, output) if !status.success? && !capture_errors

    output
  end

  def run_rails_new(options = '', capture_errors: false, keypresses: nil, version: nil)
    command = +'rails'
    if version
      ensure_rails_installed(version)
      command << " _#{version}_"
    end
    command << " new tmp/myapp -m #{File.expand_path('template.rb')}"
    command << " #{options}" if options.present?
    output = nil

    if !reuse_app?
      output = run_command(command, capture_errors: capture_errors, keypresses: keypresses)
    end

    Dir.chdir('tmp/myapp') if Dir.exist?('tmp/myapp')
    output
  end

  def assert_command_success(command)
    run_command(command)
  end

  def assert_output(expected, output)
    assert_match(expected, output) if !ENV['REUSE_APP']
  end

  def assert_file(file_path, *contents)
    assert_path_exists(file_path)
    return if !block_given? && contents.empty?
    file_content = File.read(file_path)

    yield file_content if block_given?

    contents.each { |content| assert_match(content, file_content) }
  end

  def refute_file(file_path, *contents)
    if contents.empty?
      refute_path_exists file_path
      return
    end

    assert_path_exists(file_path)

    file_content = File.read(file_path)
    contents.each { |content| refute_match(content, file_content) }
  end

  def assert_gemfile(*contents, &)
    assert_file('Gemfile', *contents, &)
  end

  def refute_gemfile(*contents, &)
    refute_file('Gemfile', *contents, &)
  end

  def assert_dir(dir_path)
    assert_path_exists dir_path
    assert File.directory?(dir_path)
  end

  def refute_dir(dir_path)
    refute_path_exists dir_path
  end

  def assert_test_file(test_file_partial_path, *contents, &)
    suffix = rspec? ? '_spec.rb' : '_test.rb'

    assert_file("#{test_folder}/#{test_file_partial_path}#{suffix}", *contents, &)
  end

  def assert_test_data_file(name, *contents, &)
    ext = factory_bot? ? 'rb' : 'yml'

    assert_file("#{test_folder}/#{test_data_folder}/#{name}.#{ext}", *contents, &)
  end

  def assert_commit(commit_message)
    assert_includes commits, commit_message
  end

  def commits
    @commits ||= run_command('git log --pretty=format:%s').split("\n")
  end

  def rspec?
    @rspec ||= Dir.exist?('spec')
  end

  def factory_bot?
    @factory_bot ||= File.read('Gemfile').include?('factory_bot')
  end

  def css_framework?
    @css_framework ||= Dir['**/tailwind/application.css', '**/application.bootstrap.scss'].any?
  end

  def with_clean_env
    run_command('bin/rails db:environment:set RAILS_ENV=test')
    with_clean_rubocop { yield }
  ensure
    run_command('bin/rails db:environment:set RAILS_ENV=development')
  end

  def with_clean_rubocop
    return if !File.exist?('.rubocop.yml')
    rubocop_path = "#{root_path}/.rubocop.yml"
    rubocop_content = File.read(rubocop_path)
    FileUtils.rm rubocop_path

    yield
  ensure
    File.write(rubocop_path, rubocop_content)
  end

  private

  def raise_failed(command, output)
    decoration = '#' * 30
    message = "Command `#{command}` failed.\n"

    message << <<~EOS if output.present?

      #{decoration}###############{decoration}
      #{decoration} STDOUT START #{decoration}
      #{decoration}###############{decoration}\n
      #{output}
      #{decoration}#############{decoration}
      #{decoration} STDOUT END #{decoration}
      #{decoration}#############{decoration}
    EOS

    raise message
  end

  def ensure_rails_installed(version)
    run_command("gem install rails -v #{version} --conservative")
  end

  def reuse_app?
    if ENV['REUSE_APP']
      if Dir.exist?('tmp/myapp')
        return true
      else
        puts "my_app is missing. Running `rails new`...\n\n"
      end
    end

    false
  end

  def test_folder
    rspec? ? 'spec' : 'test'
  end

  def test_data_folder
    factory_bot? ? 'factories' : 'fixtures'
  end
end
