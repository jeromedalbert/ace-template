module Options
  attr_accessor :template_options

  def parse_template_options
    parse_options

    imply_options
    set_options_defaults
    ensure_compatible_options
  end

  def asset_pipeline?
    !skip_asset_pipeline?
  end

  def action_cable?
    !skip_action_cable?
  end

  def active_job?
    !options[:skip_active_job]
  end

  def active_record?
    !skip_active_record?
  end

  def ci?
    !skip_ci?
  end

  def docker?
    !options[:skip_docker]
  end

  def kamal?
    !skip_kamal?
  end

  def rubocop?
    !skip_rubocop?
  end

  def solid?
    !skip_solid?
  end

  def skip_some_rails_defaults?
    !template_options[:noskip]
  end

  def db
    options[:database].inquiry
  end

  def rails_main?
    options.main?
  end

  def server_db?
    !skip_active_record? && !sqlite3?
  end

  def redis?
    @has_redis ||= File.read('Gemfile').include?('redis')
  end

  def with_rails_options(**rails_options)
    old_rails_options = options
    old_required_railties = @required_railties
    self.options = options.merge(rails_options)
    @required_railties = nil

    yield

    self.options = old_rails_options
    @required_railties = old_required_railties
  end

  private

  def parse_options
    @template_options = {}
    @raw_template_options =
      Thor::Options
        .new(_: Thor::Option.new(:template_options, { aliases: '-o' }))
        .parse(ARGV)
        .dig('template_options')
    return if @raw_template_options.nil?

    show_help if @raw_template_options.in?(%w[h help template_options])
    ensure_valid_app_path
    allowed_options = Template::HELP_BANNER.scan(/^  ([a-z_]+).*#/).flatten

    @raw_template_options
      .split(',')
      .each do |option|
        option_key, option_value = option.split('=')
        if !option_key.underscore.in?(allowed_options)
          emit_template_error("Invalid template option: #{option_key}")
        end
        @template_options[option_key.underscore.to_sym] = option_value || true
      end
  end

  def show_help
    delete_created_app

    puts "\n#{Template::HELP_BANNER}\n"

    exit
  end

  def ensure_valid_app_path
    emit_template_error 'First argument must be the app path' if app_path.start_with?('-')
  end

  def imply_options
    if @template_options[:all]
      @template_options.merge!(
        auth: true,
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
      @template_options.merge!(
        active_storage: true,
        auth: true,
        banana: true,
        squash: true,
        vcr: true
      )
    end

    @template_options[:solid_dev] = true if @template_options[:worker] && solid?
  end

  def set_options_defaults
    set_multi_option_default(:auth, 'rails')
    set_multi_option_default(:errors, 'rollbar')
  end

  def set_multi_option_default(option, default)
    if @template_options.key?(option) && !@template_options[option].is_a?(String)
      @template_options[option] = default
    end
  end

  def ensure_compatible_options
    if options[:skip_bundle]
      emit_template_error 'This template is incompatible with Rails --skip-bundle option'
    end
    if options[:skip_git]
      emit_template_error 'This template is incompatible with Rails --skip-git option'
    end

    if @template_options[:active_storage] && skip_active_storage?
      emit_template_error 'active_storage template option is incompatible with Rails --skip-active-storage option'
    end

    if @template_options[:worker]
      emit_template_error 'worker template option requires Rails --api option' if !options[:api]
      if options[:skip_active_job]
        emit_template_error 'worker template option is incompatible with Rails --skip-active-job option'
      end
    end

    if @template_options[:solid_dev]
      if skip_solid?
        emit_template_error 'solid_dev template option is incompatible with Rails --skip-solid option'
      elsif !options[:database].in?(Template::SUPPORTED_DATABASES)
        emit_template_error 'solid_dev template option currently only works for ' \
                              "#{Template::SUPPORTED_DATABASES.to_sentence}."
      end
    end
  end
end

extend Options
