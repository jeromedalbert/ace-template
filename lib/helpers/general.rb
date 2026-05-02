module General
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
end

extend General
