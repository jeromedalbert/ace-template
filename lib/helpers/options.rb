require_relative '../cli/template_option_parser'

module Options
  attr_accessor :template_options

  def parse_template_options
    result = CLI::TemplateOptionParser.new(self).parse(ARGV)

    @template_options = result.template_options
    @selected_options_string = result.selected_options_string
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
end

extend Options
