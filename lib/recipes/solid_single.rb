module ConfigureSolidSingle
  def perform
    setup_config_files

    replace_schema_with_migration('db/cable_schema.rb', 'CreateSolidCableTable')
    replace_schema_with_migration('db/cache_schema.rb', 'CreateSolidCacheTable')
    replace_schema_with_migration('db/queue_schema.rb', 'CreateSolidQueueTables')

    commit 'Configure Solid adapters to use a single database'
  end

  private

  def setup_config_files
    gsub_file 'config/cable.yml', /^ *connects_to:\n(    .*\n)*/, ''
    delete_line 'config/cache.yml', %r{ *database: .*}
    delete_line 'config/environments/production.rb', %r{ *config.solid_queue.connects_to .*}

    if server_db?
      gsub_file 'config/cable.yml', /polling_interval: .*/, 'polling_interval: 3.seconds'

      gsub_file 'config/queue.yml', /(dispatchers:\n.*polling_interval:).*/, '\1 10'
      gsub_file 'config/queue.yml', /batch_size: .*/, 'batch_size: 25'
      gsub_file 'config/queue.yml', /(workers:\n(.*\n)*.*polling_interval:).*/, '\1 5'
    end
  end

  def replace_schema_with_migration(schema_file, migration_name)
    run "rails generate migration #{migration_name}"

    migration_file = find_file("db/migrate/*_#{migration_name.underscore}.rb")
    schema_content = File.read(schema_file)[/ActiveRecord::Schema.*define.* do\n((.*\n)*)end/m, 1]
    gsub_file migration_file, /(  def change\n)(    .*\n)*/, "\\1#{schema_content.indent(2)}"
    format_code migration_file

    remove_file schema_file
  end
end

extend ConfigureSolidSingle
perform
