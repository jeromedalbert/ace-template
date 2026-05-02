remove_dir 'app/controllers'
remove_dir 'app/views'
remove_dir 'public'
remove_dir 'spec/controllers'

remove_file 'config.ru'
remove_file 'config/puma.rb'
remove_file 'config/routes.rb'
remove_file 'config/initializers/cors.rb'
remove_file controller_test_helper_file_path

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
add_test_file 'services/say_hello', from: 'worker'

commit 'Remove web code'
