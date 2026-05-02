module Helpers
  attr_accessor :template_options

  private

  def emit_critical_error(message)
    say("\n[ERROR] #{message}\nApp generation aborted.\n\n", :red)
    abort
  end

  def solid?
    !skip_solid?
  end

  def parse_template_options
    @template_options = {}
    raw_options = Thor::Options.new(_: Thor::Option.new(:template_options, { aliases: '-o' }))
    raw_options = raw_options.parse(ARGV)['template_options']
    return if raw_options.nil? || raw_options == 'template_options'
    allowed_options = Template::TEMPLATE_OPTIONS_BANNER.scan(/- ([a-z-]*).*:/).flatten

    raw_options
      .split(',')
      .each do |option|
        option_key, option_value = option.split('=')
        if !option_key.in?(allowed_options)
          emit_critical_error("Invalid template option: #{option_key}")
        end
        @template_options[option_key.underscore.to_sym] = option_value || true
      end

    if @template_options[:all]
      @template_options.merge!(
        dependabot: true,
        errors: true,
        generators: true,
        omakase: true,
        pundit: true,
        redis: true,
        solid_dev: true
      )
    end
    if @template_options[:omakase]
      @template_options.merge!(banana: true, devise: true, squash: true, vcr: true)
    end
    @template_options[:solid_dev] = true if @template_options[:worker] && solid?
    set_multi_option_default(:errors, 'rollbar')

    if @template_options[:worker] && !options[:api]
      emit_critical_error 'worker template option requires Rails --api option'
    end
    if @template_options[:solid_dev]
      if skip_solid?
        emit_critical_error 'solid-dev template option is incompatible with Rails --skip-solid option'
      elsif !options[:database].in?(Template::SUPPORTED_DATABASES)
        emit_critical_error 'solid-dev template option currently only works for ' \
                              "#{Template::SUPPORTED_DATABASES.to_sentence}."
      end
    end
  end

  def set_multi_option_default(option, default)
    if @template_options.key?(option) && !@template_options[option].is_a?(String)
      @template_options[option] = default
    end
  end

  def db
    options[:database].inquiry
  end

  def server_db?
    !skip_active_record? && !sqlite3?
  end

  def redis?
    @has_redis ||= File.read('Gemfile').include?('redis')
  end

  def active_storage?
    !skip_active_storage?
  end

  def action_cable?
    !skip_action_cable?
  end

  def asset_pipeline?
    !skip_asset_pipeline?
  end

  def ci?
    !skip_ci?
  end

  def partial(file_path, *nl_opts, **opts)
    prepend = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:prepend_nl)
    prepend ||= opts[:surround] || opts[:prepend]
    append = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:append_nl)
    append ||= opts[:surround] || opts[:append]
    indent = opts[:indent] || 0

    file_path =
      file_path
        .split('/')
        .tap { |components| components[-1] = "_#{components[-1]}" }
        .join('/')
        .then { |path| find_in_source_paths(path) }

    file_content = File.read(file_path)
    if file_path.end_with?('.tt')
      file_content = ERB.new(file_content, trim_mode: '-').result(binding)
    end

    prepend.to_s + indent(file_content, indent) + append.to_s
  end

  def commit(message = 'Initial commit', files: '--all')
    if `git status --porcelain`.empty?
      emit_critical_error %(Cannot commit with message "#{message}": there are no files to commit.)
    end

    run "git add #{files}"
    run "git commit -m '#{message}'", capture: true
  end

  def remove_comments(file, remove_yml_extra_lines: true)
    delete_line file, /^ *#.*/

    gsub_file file, /\n{3,}/, "\n\n"
    if File.extname(file) == '.yml' && remove_yml_extra_lines
      gsub_file file, /\n{2,}(  .*)/, "\n\\1"
    end

    gsub_file file, /\A\n+/, ''
    gsub_file file, /^\n+\z/, ''
    gsub_file file, /\n\nend/, "\nend"
  end

  def run(command, config = {})
    abort_on_failure = config.fetch(:abort_on_failure, true)
    return super if !abort_on_failure || !config[:capture]
    destination = relative_to_original_destination_root(destination_root, false)
    say_status :run, "#{command} from #{destination.inspect}", config.fetch(:verbose, true)

    result, status = Open3.capture2e(command.to_s)

    status.success? ? result : emit_critical_error(result)
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

  def delete_line(file_path, line_regex)
    gsub_file file_path, /^#{line_regex}\n/, ''
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

  def timezone
    @timezone ||= run('rake time:zones:local', verbose: false, capture: true).split("\n")[2]
  end

  def app_title
    app_name.sub(/([^[:punct:]])app$/, '\1 app').titleize
  end

  def app_uniqueish_name
    delimiter = app_name[/[_-]/]
    unprefixed_name = app_name.remove(/^(my|cool|great|amazing)#{delimiter}?/)
    stripped_name = unprefixed_name.parameterize.remove('-', /app$/)

    if stripped_name.in?(['', 'test', 'sample', 'blog', 'project'])
      "#{Etc.getlogin}#{delimiter}#{unprefixed_name}"
    else
      app_name
    end
  end

  def emit_warning(message)
    say("\n[WARNING] #{message}\n\n", :yellow)
  end

  def emit_success(message)
    say("\n#{message}\n\n", :green)
  end

  def find_file(pattern)
    Dir[pattern].first
  end

  def rails_file(gem_name, file_path)
    gem_version = Bundler.definition.specs[gem_name].first.version
    version_path = options.main? ? 'main' : "refs/tags/v#{gem_version}"

    "https://raw.githubusercontent.com/rails/#{gem_name}/#{version_path}/#{file_path}"
  end

  def get_rails_file(gem_name, file_path, destination)
    get(rails_file(gem_name, file_path), destination)
  end
end

extend Helpers
