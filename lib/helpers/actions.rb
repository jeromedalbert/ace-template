require 'bundler'
require 'open3'

module Actions
  def run(command, config = {})
    abort_on_failure = config.fetch(:abort_on_failure, true)
    return super if !abort_on_failure || !config[:capture]
    destination = relative_to_original_destination_root(destination_root, false)
    display_command = "#{command} from #{destination.inspect}"
    verbose = config.fetch(:verbose, true)
    say_status :run, display_command, verbose

    result, status = Open3.capture2e(command.to_s)

    if status.success?
      result
    else
      say_status :run, display_command if !verbose
      emit_critical_error(result)
    end
  end

  def format_code(files = nil)
    if template_options[:omakase]
      format_rubocop(files)
      return
    end

    stree_files = files || '**/*'
    command = ["bundle exec stree write '#{stree_files}'"]
    command += File.read(find_in_source_paths('.streerc')).split if !File.exist?('.streerc')
    run command.join(' '), capture: true, abort_on_failure: false

    if !@formatted_gemfile
      format_rubocop(
        '--only Bundler/OrderedGems --config ' + find_in_source_paths('.rubocop.internal.yml')
      )
      @formatted_gemfile = true
    end
  end

  def format_rubocop(options = '')
    return if skip_rubocop?

    run "bundle exec rubocop -A #{options} --ignore-parent-exclusion".squish,
        capture: true,
        verbose: false
  end

  def show_help
    delete_created_app

    puts "\n#{Template::HELP_BANNER}\n"

    exit
  end

  def delete_created_app
    remove_dir(destination_root, verbose: false) if @app_created
  end

  def emit_template_error(message)
    delete_created_app

    say("\n[ERROR] #{message}\n\n", :red)

    abort
  end

  def emit_critical_error(message)
    say("\n[ERROR] #{message}\nApp generation aborted.\n\n", :red)
    abort
  end

  def emit_warning(message)
    say("\n[WARNING] #{message}\n\n", :yellow)
  end

  def emit_info(message)
    say("\n[INFO] #{message}\n\n")
  end

  def emit_success(message)
    say("\n#{message}\n\n", :green)
  end

  def commit(message = 'Initial commit', files: nil, errors: true)
    if `git status --porcelain`.empty?
      if errors
        emit_critical_error %(Cannot commit with message "#{message}": there are no files to commit.)
      else
        return
      end
    end

    if template_options[:omakase]
      format_rubocop('--config ' + find_in_source_paths('omakase/.rubocop.internal.yml'))
    elsif template_options[:double]
      format_rubocop('--config ' + find_in_source_paths('double/.rubocop.internal.yml'))
    end

    run "git add #{files || '--all'}"
    run "git commit -m '#{message}'", capture: true
  end

  def comment_lines(file_path, line_pattern)
    gsub_file(file_path, line_pattern) do |match|
      indent_count = match.lines.first[/^ */].length

      match.lines.map { |line| "#{' ' * indent_count}# #{line[indent_count..]}" }.join
    end
  end

  def uncomment_lines(file_path, line_pattern)
    return super if line_pattern.to_s.exclude?('#')

    gsub_file(file_path, line_pattern) do |match|
      match.lines.map { |line| line.sub(/(^ )*# /, '\1') }.join
    end
  end

  def remove_comments(file_path, remove_yml_extra_lines: true)
    delete_line file_path, /^ *#.*/

    gsub_file file_path, /\n{3,}/, "\n\n"
    if File.extname(file_path) == '.yml' && remove_yml_extra_lines
      gsub_file file_path, /\n{2,}(  .*)/, "\n\\1"
    end

    gsub_file file_path, /\A\n+/, ''
    gsub_file file_path, /^\n+\z/, ''
    gsub_file file_path, /\n\nend/, "\nend"
  end

  def remove_comments_before(file_path, line_pattern)
    gsub_file file_path, /(^ *#.*\n)*(?=^ *#{line_pattern})/, ''
  end

  def cleanup_binstub(binstub_name)
    gsub_file "bin/#{binstub_name}", /# (.*\n)*?require/, 'require'
    gsub_file "bin/#{binstub_name}", /\n\n/, "\n"
    format_code "bin/#{binstub_name}"
  end

  def add_test_file(file_partial_path, from: 'tests')
    return if !tests?
    source_folder = +from
    source_folder << (rspec? ? '/rspec' : '/rails') if source_folder == 'tests'
    source_folder << "/#{test_folder}"

    file_path = file_partial_path + (rspec? ? '_spec.rb' : '_test.rb')

    template "#{source_folder}/#{file_path}", "#{test_folder}/#{file_path}", force: true
  end

  def add_test_data_file(name, from:)
    return if !tests?
    test_data_folder = factory_bot? ? 'factories' : 'fixtures'
    ext = factory_bot? ? 'rb' : 'yml'

    template "#{from}/#{test_data_folder}/#{name}.#{ext}",
             "#{test_folder}/#{test_data_folder}/#{name}.#{ext}",
             force: true
  end

  def copy_file_from(folder, file_path, ...)
    copy_file("#{folder}/#{file_path}", file_path, ...)
  end

  def directory_from(folder, dir_path, ...)
    directory("#{folder}/#{dir_path}", dir_path, ...)
  end

  def template_from(folder, file_path, ...)
    template("#{folder}/#{file_path}", file_path.chomp('.tt'), ...)
  end

  def add_before_end(file_path, content)
    insert_into_file file_path, content, before: /^end\n\z/
  end

  def delete_line(file_path, line_pattern)
    gsub_file file_path, /^#{line_pattern}\n/, ''
  end

  def move_line(file_path, line_pattern, *nl_opts, **opts)
    line = File.read(file_path)[/^#{line_pattern}/]
    line.prepend("\n") if nl_opts.include?(:prepend_nl) || nl_opts.include?(:surround_nl)
    line << "\n" if nl_opts.include?(:prepend_nl) || nl_opts.include?(:surround_nl)

    delete_line file_path, line_pattern
    insert_into_file file_path, line, opts
  end

  def format_quotes(files)
    from, to =
      if template_options[:double]
        %w[' "]
      else
        %w[" ']
      end

    Dir[*files].each { |file| gsub_file(file, from, to) }
  end

  def find_file(pattern)
    Dir[pattern].first
  end

  def copy_gem_file(gem_name, file_path, destination)
    copy_file(gem_file(gem_name, file_path), destination)
  end

  def gem_file(gem_name, file_path)
    @gem_paths ||= {}

    @gem_paths[gem_name] ||= `bundle show #{gem_name}`.chomp

    gem_path = @gem_paths[gem_name]
    "#{gem_path}/#{file_path}"
  end

  def move_block(file_path, block_start, **options)
    block = File.read(file_path)[ruby_block_regex(block_start)]

    delete_block(file_path, block_start)
    insert_into_file file_path, block, options
  end

  def ruby_block_regex(block_start)
    spaces_count = block_start[/^ */].length
    spaces = ' ' * spaces_count

    /#{Regexp.escape(block_start)}\n((#{spaces}  .*\n|\n)*)#{spaces}end\n\n?/
  end

  def delete_block(file_path, block_start)
    gsub_file file_path, ruby_block_regex(block_start), ''
  end

  def split_var_from_condition(file_path, variable)
    gsub_file file_path, /( *)if (#{variable} = .*)/, "\\1\\2\n\n\\1if #{variable}"
  end

  def insert_blank_line(file_path, line_pattern)
    gsub_file file_path, /#{line_pattern}/, "\\0\n"
  end

  def add_private(file_path)
    add_before_end(file_path, "  private\n") if !File.read(file_path).match?(/^  private/)
  end
end

extend Actions
