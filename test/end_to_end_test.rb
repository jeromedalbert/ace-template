require 'test_helper'

class EndToEndTest < Minitest::Test
  def setup
    Dir.chdir("#{__dir__}/..")

    FileUtils.rm_rf('myapp') if !ENV['REUSE_APP']

    @commits = nil
    @env = nil
  end

  private

  def run_command(command, capture_errors: false)
    method = capture_errors ? :capture2e : :capture2
    command = "#{@env} #{command}" if @env

    output, status = Bundler.with_original_env { Open3.send(method, command) }
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

  def run_rails_new(options = '', capture_errors: false)
    command = "rails new myapp -m #{File.expand_path('template.rb')}"
    command << " #{options}" if options.present?

    output = reuse_app? ? nil : run_command(command, capture_errors: capture_errors)

    Dir.chdir('myapp') if Dir.exist?('myapp')
    output
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
