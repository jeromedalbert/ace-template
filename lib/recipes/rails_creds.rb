module ConfigureRailsCreds
  def perform
    write_credentials
    setup_local_overrides
  end

  private

  def write_credentials
    credentials = read_template('rails_creds/config/credentials.yml.tt')

    ActiveSupport::EncryptedConfiguration.new(
      config_path: 'config/credentials.yml.enc',
      key_path: 'config/master.key',
      env_key: 'RAILS_MASTER_KEY',
      raise_if_missing_key: true
    ).write(credentials)
  end

  def setup_local_overrides
    template_from 'rails_creds', 'config/local.rb.sample.tt'

    insert_into_file '.gitignore', "/config/local.rb\n", after: ".env*\n"
    insert_into_file '.dockerignore', "/config/local.rb\n", after: ".env*\n" if docker?

    gsub_file 'bin/setup', /^ *# (.*Copying sample files.*)\n( *# .*\n)*/, <<-EOS
  \\1
  FileUtils.cp 'config/local.rb.sample', 'config/local.rb' unless File.exist?('config/local.rb')
    EOS
  end
end

extend ConfigureRailsCreds
perform
