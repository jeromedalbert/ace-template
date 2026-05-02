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

  def dotenv?
    !template_options[:rails_creds]
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

  def tests?
    !options[:skip_test]
  end

  def template_defaults?
    !template_options[:omakase]
  end

  def db
    options[:database]
  end

  def server_db?
    active_record? && !sqlite3?
  end

  def postgresql?
    db == 'postgresql'
  end

  def mysql?
    db.match?(/mysql|trilogy|mariadb/)
  end

  def single_db?
    skip_solid? || template_options[:solid_single]
  end

  def multiple_dbs?
    !single_db?
  end

  def redis?
    @has_redis ||= File.read('Gemfile').include?('redis')
  end

  def any_kamal_creds?
    kamal? && template_options[:rails_creds] && (server_db? || redis?)
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
