module ConfigureDatabase
  def perform
    if server_db?
      configure_server_db
    elsif sqlite3?
      configure_sqlite
    end

    commit 'Configure database', errors: false
  end

  private

  def configure_server_db
    gsub_file 'config/database.yml',
              /database: #{app_name}_production$/,
              "url: <%= ENV['DATABASE_URL'] %>"
    delete_line 'config/database.yml', /^ *username:.*/
    delete_line 'config/database.yml', /^ *password:.*/
    if mysql?
      insert_into_file 'config/database.yml',
                       "  username: root\n",
                       after: /^  (pool|max_connections): .*\n/
    end

    if single_db?
      gsub_file 'config/database.yml', /^production:\n.*/m, <<~EOS
        production:
          <<: *default
          url: <%= ENV['DATABASE_URL'] %>
      EOS
    else
      gsub_file 'config/database.yml',
                /database: #{app_name}_production_(.*)/,
                "url: <%= URI.parse(ENV['DATABASE_URL']).tap { |u| u.path += '_\\1' } if ENV['DATABASE_URL'] %>"
    end

    format_quotes('config/database.yml', style: :single)
    configure_solid_dev_dbs if template_options[:solid_dev] && multiple_dbs?
  end

  def configure_solid_dev_dbs
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
    if single_db?
      gsub_file 'config/database.yml', /^production:\n.*/m, <<~EOS
        production:
          <<: *default
          database: storage/production.sqlite3
      EOS
    elsif template_options[:solid_dev]
      configure_solid_dev_dbs
      gsub_file 'config/database.yml', %r{(    database: storage/)production}, '\1<%= Rails.env %>'
    end
  end
end

extend ConfigureDatabase
perform
