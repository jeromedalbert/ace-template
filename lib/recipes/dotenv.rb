remove_file 'config/credentials.yml.enc'
remove_file 'config/master.key'

template_from 'dotenv', '.env.sample.tt'
insert_into_file '.gitignore', "!/.env.sample\n", after: ".env*\n"
insert_into_file '.dockerignore', "!/.env.sample\n", after: ".env*\n" if docker?

gsub_file 'bin/setup', /^ *# (.*Copying sample files.*)\n( *# .*\n)*/, <<-EOS
  \\1
  FileUtils.cp '.env.sample', '.env' unless File.exist?('.env')
EOS
commit 'Replace Rails credentials with Dotenv'
