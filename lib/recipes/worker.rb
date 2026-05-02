remove_dir 'app/controllers'
remove_dir 'app/views'
remove_dir 'public'
remove_dir 'spec/controllers'

remove_file 'config.ru'
remove_file 'config/puma.rb'
remove_file 'config/routes.rb'
remove_file 'config/initializers/cors.rb'
remove_file 'spec/support/controller_helpers.rb'

comment_lines 'config/application.rb', "require 'action_controller/railtie'"

File.write 'Procfile.dev', "worker: bin/jobs\n"
gsub_file 'bin/dev', /exec .*/, "exec 'bin/jobs', *ARGV"
if docker?
  gsub_file 'Dockerfile', /# Start server.*/, '# Start background jobs'
  gsub_file 'Dockerfile', /EXPOSE .*\nCMD .*/, 'CMD ["bin/jobs"]'
  gsub_file 'bin/docker-entrypoint', 'running the rails server', 'processing jobs'
  gsub_file 'bin/docker-entrypoint', %r{if .*bin/rails.*then}, 'if [ $1 == "bin/jobs" ]; then'
end

copy_file_from 'worker', 'app/services/say_hello.rb'
copy_file_from 'worker', 'spec/services/say_hello_spec.rb'

commit 'Remove web code'
