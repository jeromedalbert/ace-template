remove_comments 'config/cable.yml'
delete_line 'config/cable.yml', /development:\n(  .*\n)*/
gsub_file 'config/cable.yml', 'production:', 'production: &production'
append_to_file 'config/cable.yml', "\ndevelopment:\n  <<: *production\n"

gsub_file 'config/environments/development.rb', ':memory_store', ':solid_cache_store'
gsub_file 'config/cache.yml', /development:\n/, "\\0  database: cache\n"

insert_into_file(
  'config/environments/development.rb',
  partial('solid_dev/config/environments/development.rb.tt', :append_nl, indent: 2),
  after: /config.active_job.*\n\n/
)
