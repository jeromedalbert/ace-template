remove_file '.kamal/secrets'
template '.kamal/secrets.production.tt'
insert_into_file '.gitignore', ".kamal/secrets*\n", after: ".env.sample\n" if dotenv?
if Rails.version.to_f < 8.1 && docker?
  insert_into_file '.dockerignore', ".kamal/secrets*\n", after: ".env.sample\n"
end

cleanup_binstub('kamal')
insert_into_file 'bin/kamal', partial('bin/kamal.rb', :surround_nl), before: 'load Gem.bin_path'
create_file 'config/deploy.production.yml', "{}\n"

uncomment_lines 'config/deploy.yml', /# proxy:\n(#  .*\n)*/
remove_comments 'config/deploy.yml'
gsub_file 'config/deploy.yml', "\nimage:", 'image:'
comment_lines 'config/deploy.yml', /^proxy:\n(  .*\n)*/
remove_comments 'config/deploy.yml' if template_options[:worker]
gsub_file 'config/deploy.yml', 'your-user', "<%= ENV['KAMAL_REGISTRY_USERNAME'] %>"
gsub_file 'config/deploy.yml', /^servers:\n(  .*\n)*/, partial('config/deploy_servers.yml.tt')

secret_keys = +%q(<%= Dotenv.parse(".kamal/secrets.#{ENV['KAMAL_DESTINATION']}").keys)
secret_keys << " - ['KAMAL_REGISTRY_PASSWORD']" if Rails.version.to_f < 8.1
secret_keys << " - ['SECRETS']" if template_options[:rails_creds]
secret_keys << ' %>'
gsub_file 'config/deploy.yml', '- RAILS_MASTER_KEY', secret_keys

gsub_file 'config/deploy.yml', %r{ *clear:\n *SOLID_QUEUE_IN_PUMA.*\n$}, ''

if !template_options[:worker]
  gsub_file 'config/deploy.yml',
            /logs: app logs -f/,
            '\0 --grep-options="--invert-match --extended-regexp" --grep="^[^ ]+ \{"'
end

if server_db? || redis?
  append_to_file 'config/deploy.yml', partial('config/deploy_accessories.yml.tt', :prepend_nl)
end
append_to_file 'config/deploy.yml', partial('config/deploy_end.yml.tt')

if template_options[:double]
  gsub_file 'config/deploy.yml', "'SERVER_IP'", '"SERVER_IP"'
  gsub_file 'config/deploy.yml', "'SECRETS'", '"SECRETS"'
  gsub_file 'config/deploy.yml', "'KAMAL_REGISTRY_USERNAME'", '"KAMAL_REGISTRY_USERNAME"'
  gsub_file 'config/deploy.yml', "'KAMAL_REGISTRY_PASSWORD'", '"KAMAL_REGISTRY_PASSWORD"'
end

comment_lines 'config/environments/production.rb', /^ *config.assume_ssl = true/
comment_lines 'config/environments/production.rb', /^ *config.force_ssl = true/

template 'db/production.sql.tt' if mysql? && solid?

commit 'Configure Kamal'
