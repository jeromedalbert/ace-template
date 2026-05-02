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
          /^  (?<name>[a-z-]+)(?:\[=(?<values>[a-z\-|]*)\])? *# (?<description>.*)/
        )

      matches.each do |match|
        name = match[0].underscore
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
            if option_value == true
              option_key.dasherize
            else
              "#{option_key.dasherize}=#{option_value}"
            end
          end
          .sort
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
          option_key = option_key.underscore
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
        add_template_options(@available_options.keys - %w[all double omakase worker])
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
      check_incompatible_option(:skip_bundle)
      check_incompatible_option(:skip_git)

      check_incompatible_options(:auth, rails_option: :skip_active_record)
      check_incompatible_options(:banana, rails_option: :skip_active_record)

      check_incompatible_options(:active_storage, rails_option: :skip_active_storage)

      check_incompatible_options(:solid_dev, rails_option: :skip_solid)
      check_incompatible_options(:solid_single, rails_option: :skip_solid)

      check_incompatible_options(:worker, rails_option: :skip_active_job)
      check_required_option(:worker, required_rails_option: :api)
    end

    def check_incompatible_option(rails_option)
      if options[rails_option]
        emit_error "This template is incompatible with Rails #{to_flag(rails_option)} option"
      end
    end

    def options
      @app.options
    end

    def to_flag(option)
      display_value(option).prepend('--')
    end

    def display_value(option)
      option.to_s.dasherize
    end

    def check_incompatible_options(template_option, rails_option:)
      if @template_options[template_option] && options[rails_option]
        emit_error(
          "#{display_value(template_option)} template option is incompatible with " \
            "Rails #{to_flag(rails_option)} option"
        )
      end
    end

    def check_required_option(template_option, required_rails_option:)
      if @template_options[template_option] && !options[required_rails_option]
        emit_error(
          "#{display_value(template_option)} template option requires " \
            "Rails #{to_flag(required_rails_option)} option"
        )
      end
    end
  end
end
