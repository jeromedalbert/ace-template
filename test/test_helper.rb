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
    Dir.chdir("#{__dir__}/..")

    FileUtils.rm_rf('tmp/myapp') if !ENV['REUSE_APP']

    @commits = nil
    @env = nil
  end

  private

  def run_command(command, capture_errors: false, keypresses: nil)
    method = capture_errors ? :capture2e : :capture2
    command = "#{@env} #{command}" if @env

    output, status =
      Bundler.with_original_env { Open3.send(method, command, stdin_data: keypresses) }
    raise_failed(output) if !status.success? && !capture_errors

    output
  end

  def raise_failed(output)
    decoration = '#' * 30
    message = 'Command failed.'

    message = <<~EOS if output.present?
      #{message}

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

  def ensure_rails_installed(version)
    run_command("gem install rails -v #{version} --conservative")
  end

  def reuse_app?
    if ENV['REUSE_APP']
      if Dir.exist?("#{__dir__}/../myapp")
        return true
      else
        puts "my_app is missing. Running `rails new`...\n\n"
      end
    end

    false
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

  def assert_commit(commit_message)
    assert_includes commits, commit_message
  end

  def commits
    @commits ||= run_command('git log --pretty=format:%s').split("\n")
  end
end
