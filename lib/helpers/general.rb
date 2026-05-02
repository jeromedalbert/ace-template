module General
  def app_title
    app_name.sub(/([^[:punct:]])app$/, '\1 app').titleize
  end

  def app_uniqueish_name
    delimiter = app_name[/[_-]/]
    unprefixed_name = app_name.remove(/^(my|cool|great|amazing)#{delimiter}?/)
    stripped_name = unprefixed_name.parameterize.remove('-', /app$/)

    if stripped_name.in?(['', 'test', 'sample', 'demo', 'blog', 'project'])
      "#{Etc.getlogin}#{delimiter}#{unprefixed_name}"
    else
      app_name
    end
  end

  def timezone
    return @timezone if @timezone

    if File.exist?('/etc/localtime')
      @timezone =
        File
          .readlink('/etc/localtime')
          .split('zoneinfo/')
          .last
          .then { |zone| ActiveSupport::TimeZone::MAPPING.invert[zone] }
    end

    @timezone ||= Time.now.zone
  end

  def fly_io_launch_command
    command = +'DISABLE_SPRING=true fly launch --no-deploy'

    command << ' --no-object-storage' if sqlite3?
    command << ' --yes'
    command << ' --db=upg' if postgresql?
    command << ' --no-db' if !active_record?

    command << " --name #{app_uniqueish_name.dasherize}"
    command
  end

  def partial(file_path, *nl_opts, **opts)
    prepend = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:prepend_nl)
    prepend ||= opts[:surround] || opts[:prepend]
    append = "\n" if nl_opts.include?(:surround_nl) || nl_opts.include?(:append_nl)
    append ||= opts[:surround] || opts[:append]
    indent = opts[:indent] || 0

    file_path =
      file_path.split('/').tap { |components| components[-1] = "_#{components[-1]}" }.join('/')
    file_content = read_template(file_path)

    prepend.to_s + indent(file_content, indent) + append.to_s
  end

  def read_template(file_path)
    file_path = find_in_source_paths(file_path)
    file_content = File.read(file_path)

    if file_path.end_with?('.tt')
      file_content = ERB.new(file_content, trim_mode: '-').result(binding)
    end

    file_content
  end

  # Port of https://github.com/rails/rails/pull/56365 while waiting for it to
  # be available in all Rails versions supported by this template.
  def version_manager_ruby_version
    return ENV['RBENV_VERSION'] if ENV['RBENV_VERSION']
    return ENV['rvm_ruby_string'] if ENV['rvm_ruby_string']

    version =
      if RUBY_ENGINE == 'ruby'
        Gem.ruby_version.to_s.sub(/\.([a-zA-Z])/, '-\1')
      else
        RUBY_ENGINE_VERSION
      end

    "#{RUBY_ENGINE}-#{version}"
  end

  def help_banner
    Template::HELP_BANNER
  end
end

extend General
