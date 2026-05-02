run 'rails active_storage:install'

migration_file = find_file('db/migrate/*_create_active_storage_tables*.rb')
gsub_file migration_file, 't.references', 't.belongs_to'
format_code migration_file

commit 'Set up Active Storage'
