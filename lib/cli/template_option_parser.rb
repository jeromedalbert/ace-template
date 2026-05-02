require 'active_support/hash_with_indifferent_access'

module CLI
  class TemplateOptionParser
    Option =
      Struct.new(:name, :description, :values) do
        def default_value
          values&.first || true
        end
      end

    Result = Struct.new(:template_options, :selected_options_string)

    def initialize(app)
      @app = app
    end

    def parse(cli_args = ARGV)
      set_available_options

      parse_options(cli_args)
      imply_options
      ensure_compatible_options

      Result.new(@template_options, @selected_options_string)
    end

    private

    def set_available_options
      @available_options = HashWithIndifferentAccess.new

      matches =
        @app.help_banner.scan(
          /^  (?<name>[a-z_]+)(?:\[=(?<values>[a-z_|]*)\])? *# (?<description>.*)/
        )

      matches.each do |match|
        name = match[0]
        values = match[1]&.split('|') || []
        @available_options[name] = Option.new(name: name, values: values, description: match[2])
      end
    end

    def parse_options(cli_args)
      @raw_options =
        Thor::Options.new(
          _o: Thor::Option.new(:template_options, aliases: '-o'),
          _i: Thor::Option.new(:interactive, aliases: '-i', type: :boolean)
        ).parse(cli_args)

      if @raw_options[:interactive]
        parse_interactive_options
      else
        parse_manual_options
      end
    end

    def parse_interactive_options
      require_relative 'interactive_prompt'

      @template_options = InteractivePrompt.new(@available_options.values, app: @app).run
      return if @template_options.empty?

      @selected_options_string =
        @template_options
          .map do |option_key, option_value|
            (option_value == true) ? option_key : "#{option_key}=#{option_value}"
          end
          .join(',')
    end

    def parse_manual_options
      @template_options = HashWithIndifferentAccess.new
      raw_template_options = @raw_options['template_options']
      return if raw_template_options.nil?
      @selected_options_string = raw_template_options

      @app.show_help if raw_template_options.in?(%w[h help template_options])
      ensure_valid_app_path

      raw_template_options
        .split(',')
        .each do |raw_option|
          option_key, option_value = raw_option.split('=')
          option = @available_options[option_key]
          emit_error("Invalid template option: #{option_key}") if !option
          @template_options[option_key] = option_value || option.default_value
        end
    end

    def ensure_valid_app_path
      emit_error 'First argument must be the app path' if @app.app_path.start_with?('-')
    end

    def emit_error(message)
      @app.emit_template_error(message)
    end

    def imply_options
      if @template_options[:all]
        add_template_options(@available_options.keys - %w[all double noskip worker])
        @template_options.delete(:all)
      end

      if @template_options[:quick]
        add_template_options(%w[active_storage auth banana squash vcr])
        @template_options.delete(:quick)
      end

      @template_options[:solid_dev] = true if @template_options[:worker] && @app.solid?
    end

    def add_template_options(option_keys)
      option_keys.each do |option_key|
        @template_options[option_key] ||= @available_options[option_key].default_value
      end
    end

    def ensure_compatible_options
      if options[:skip_bundle]
        emit_error 'This template is incompatible with Rails --skip-bundle option'
      end
      emit_error 'This template is incompatible with Rails --skip-git option' if options[:skip_git]

      if @template_options[:active_storage] && options[:skip_active_storage]
        emit_error 'active_storage template option is incompatible with Rails --skip-active-storage option'
      end

      if @template_options[:solid_dev]
        if options[:skip_solid]
          emit_error 'solid_dev template option is incompatible with Rails --skip-solid option'
        elsif !options[:database].in?(@app.supported_databases)
          emit_error(
            "solid_dev template option currently only works for #{@app.supported_databases.to_sentence}."
          )
        end
      end

      if @template_options[:worker]
        emit_error 'worker template option requires Rails --api option' if !options[:api]
        if options[:skip_active_job]
          emit_error 'worker template option is incompatible with Rails --skip-active-job option'
        end
      end
    end

    def options
      @app.options
    end
  end
end
