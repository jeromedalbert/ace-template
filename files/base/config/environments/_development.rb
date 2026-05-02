config.generators.after_generate do |files|
  system("bundle exec stree write #{files.join(' ')} &> /dev/null")
end
