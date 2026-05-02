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

    format_quotes 'config/database.yml' if template_options[:double]
    configure_solid_dev_dbs if template_options[:solid_dev] && multiple_dbs?
  end

  def configure_solid_dev_dbs
    databases_config =
      File
        .read('config/database.yml')
        .match(/(?<=production:\n).*/m)
        .to_a
        .first
        .remove(' &primary_production')
        .gsub('primary_production', 'default')

    if dotenv? || sqlite3?
      gsub_file 'config/database.yml', /production:.*/m, "production:\n  <<: *databases\n"
      insert_into_file 'config/database.yml',
                       "databases: &databases\n#{databases_config}\n",
                       before: 'development:'
      gsub_file 'config/database.yml', /development:\n(  .*\n)*/, "development:\n  <<: *databases\n"
    else
      databases_config.sub!(/url: .*cache.*/, "database: #{app_name}_development_cache")
      databases_config.sub!(/url: .*queue.*/, "database: #{app_name}_development_queue")
      databases_config.sub!(/url: .*cable.*/, "database: #{app_name}_development_cable")
      databases_config.sub!(/url: .*/, "database: #{app_name}_development")
      gsub_file 'config/database.yml',
                /development:\n(  .*\n)*/,
                "development:\n#{databases_config}"
    end
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
