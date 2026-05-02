remove_file '.kamal/secrets'
template '.kamal/secrets.production.tt'
insert_into_file '.gitignore', ".kamal/secrets*\n", after: ".env.sample\n"
if Rails.version == '8.0.0' && docker?
  insert_into_file '.dockerignore', ".kamal/secrets*\n", after: ".env.sample\n"
end

insert_into_file 'bin/kamal', partial('bin/kamal.rb', :append_nl), before: 'load Gem.bin_path'
create_file 'config/deploy.production.yml', "{}\n"

remove_comments 'config/deploy.yml'
gsub_file 'config/deploy.yml', "\nimage:", 'image:'
gsub_file 'config/deploy.yml', /^proxy:\n(  .*\n)*/ do |match|
  match.lines.map { |line| "# #{line}" }.join
end
remove_comments 'config/deploy.yml' if template_options[:worker]
gsub_file 'config/deploy.yml', 'your-user', "<%= ENV['KAMAL_REGISTRY_USERNAME'] %>"
gsub_file 'config/deploy.yml', /^servers:\n(  .*\n)*/, partial('config/deploy_servers.yml.tt')
gsub_file 'config/deploy.yml',
          '- RAILS_MASTER_KEY',
          %q(<%= Dotenv.parse(".kamal/secrets.#{ENV['KAMAL_DESTINATION']}").keys - ['KAMAL_REGISTRY_PASSWORD'] %>)
gsub_file 'config/deploy.yml', %r{ *clear:\n *SOLID_QUEUE_IN_PUMA.*\n$}, ''
gsub_file 'config/deploy.yml', %r{("bin/rails dbconsole)"}, '\1 --include-password"'
if !template_options[:worker]
  gsub_file 'config/deploy.yml',
            /logs: app logs -f/,
            '\0 --grep-options="--invert-match --extended-regexp" --grep="^[^ ]+ \{"'
end
if server_db? || redis?
  append_to_file 'config/deploy.yml', partial('config/deploy_accessories.yml.tt', :prepend_nl)
end
append_to_file 'config/deploy.yml', partial('config/deploy_end.yml.tt', :prepend_nl)

gsub_file 'config/environments/production.rb', 'assume_ssl = true', 'assume_ssl = false'
gsub_file 'config/environments/production.rb', 'force_ssl = true', 'force_ssl = false'

template 'db/production.sql.tt' if db.mysql? && solid?

commit 'Configure Kamal'
