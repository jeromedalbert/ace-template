require 'bundler'
require 'open3'

module Actions
  def run(command, config = {})
    abort_on_failure = config.fetch(:abort_on_failure, true)
    return super if !abort_on_failure || !config[:capture]
    destination = relative_to_original_destination_root(destination_root, false)
    say_status :run, "#{command} from #{destination.inspect}", config.fetch(:verbose, true)

    result, status = Open3.capture2e(command.to_s)

    status.success? ? result : emit_critical_error(result)
  end

  def emit_critical_error(message)
    say("\n[ERROR] #{message}\nApp generation aborted.\n\n", :red)
    abort
  end

  def emit_warning(message)
    say("\n[WARNING] #{message}\n\n", :yellow)
  end

  def emit_success(message)
    say("\n#{message}\n\n", :green)
  end

  def commit(message = 'Initial commit', files: '--all')
    if `git status --porcelain`.empty?
      emit_critical_error %(Cannot commit with message "#{message}": there are no files to commit.)
    end

    run "git add #{files}"
    run "git commit -m '#{message}'", capture: true
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

  def format_quotes(files, style:)
    from, to =
      if style == :single
        %w[" ']
      elsif style == :double
        %w[' "]
      end

    Dir[*files].each { |file| gsub_file file, from, to }
  end

  def find_file(pattern)
    Dir[pattern].first
  end

  def get_rails_file(gem_name, file_path, destination)
    get(rails_file(gem_name, file_path), destination)
  end

  def rails_file(gem_name, file_path)
    version_path =
      if rails_main?
        'main'
      else
        gem_version = Bundler.definition.specs[gem_name].first.version
        "refs/tags/v#{gem_version}"
      end

    "https://raw.githubusercontent.com/rails/#{gem_name}/#{version_path}/#{file_path}"
  end

  def move_block(file_path, block_start, **options)
    block = File.read(file_path)[ruby_block_regex(block_start)]

    delete_block(file_path, block_start)
    insert_into_file file_path, block, options
  end

  def ruby_block_regex(block_start)
    spaces_count = block_start[/^ */].length
    spaces = ' ' * spaces_count

    /#{Regexp.escape(block_start)}\n((#{spaces}  .*\n)*)#{spaces}end\n\n?/
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
end

extend Actions
