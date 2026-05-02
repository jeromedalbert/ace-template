# Make production the default Kamal destination
require 'thor'
destination =
  Thor::Options.new(_: Thor::Option.new(:destination, { aliases: '-d' })).parse(ARGV)['destination']
if destination.nil?
  destination = 'production'
  ARGV.push('-d', 'production')
end

# Make environment variables accessible anywhere in config/deploy.yml with ENV['MY_VAR']
require 'dotenv'
Dotenv.load(".kamal/secrets.#{destination}")

# Custom "open" command to open app in a web browser
if ARGV[0] == 'open'
  cmd =
    case RbConfig::CONFIG['host_os']
    when /mswin|mingw|cygwin/
      'start'
    when /darwin/
      'open'
    when /linux|bsd/
      'xdg-open'
    end
  system(cmd, "http://#{ENV['SERVER_IP']}")
end
