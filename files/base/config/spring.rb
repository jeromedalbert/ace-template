# Monkey patch to fix some CPU leak issues for some macOS users
class Spring::Watcher::Listen
  def base_directories
    %w[app config lib spec].map { |path| Pathname.new(File.join(root, path)) }
  end
end

%w[.ruby-version .rbenv-vars tmp/restart.txt tmp/caching-dev.txt].each { |path| Spring.watch(path) }
