# Make production the default Kamal destination
require 'thor'
destination =
  Thor::Options.new(_: Thor::Option.new(:destination, { aliases: '-d' })).parse(ARGV)['destination']
if destination.nil?
  destination = 'production'
  ARGV.push('-d', 'production')
end
ENV['KAMAL_DESTINATION'] = destination
