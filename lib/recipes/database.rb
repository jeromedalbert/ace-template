module ConfigureDatabase
  def perform
    if server_db?
      configure_server_db
    elsif sqlite3?
      configure_sqlite
    end
  end

  private

  def configure_server_db
    gsub_file 'config/database.yml',
              /database: #{app_name}_production$/,
              "url: <%= ENV['DATABASE_URL'] %>"
    gsub_file 'config/database.yml',
              /database: #{app_name}_production_(.*)/,
              "url: <%= URI.parse(ENV['DATABASE_URL']).tap { |u| u.path += '_\\1' } if ENV['DATABASE_URL'] %>"
    format_quotes('config/database.yml', style: :single)

    delete_line 'config/database.yml', /^ *username:.*/
    delete_line 'config/database.yml', /^ *password:.*/
    insert_into_file 'config/database.yml', "  username: root\n", after: /pool: .*\n/ if db.mysql?
    configure_solid_dev_db if template_options[:solid_dev]

    commit 'Configure database'
  end

  def configure_solid_dev_db
    database_yml_content =
      File.read('config/database.yml').sub(/(?<=production:\n)(  .*\n)*/, "  <<: *databases\n")
    databases_config =
      Regexp.last_match(0).remove(' &primary_production').gsub('primary_production', 'default')

    File.write 'config/database.yml', database_yml_content
    insert_into_file 'config/database.yml',
                     "databases: &databases\n#{databases_config}\n",
                     before: 'development:'

    gsub_file 'config/database.yml', /development:\n(  .*\n)*/, "development:\n  <<: *databases\n"
  end

  def configure_sqlite
    return if !template_options[:solid_dev]

    configure_solid_dev_db
    gsub_file 'config/database.yml', %r{(    database: storage/)production}, '\1<%= Rails.env %>'

    commit 'Configure database'
  end
end

extend ConfigureDatabase
perform
