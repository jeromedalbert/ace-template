config.file_watcher = ActiveSupport::EventedFileUpdateChecker

config.generators.after_generate do |files|
  system("bundle exec stree write #{files.join(' ')} &> /dev/null")
end
