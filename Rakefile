require 'minitest/test_task'
require 'rubocop/rake_task'
require 'syntax_tree/rake_tasks'

Minitest::TestTask.create

files_to_lint = `git ls-files '*.rb' Gemfile Rakefile | grep -v files`.split("\n")
RuboCop::RakeTask.new { |task| task.patterns = files_to_lint }
SyntaxTree::Rake::CheckTask.new { |t| t.source_files = files_to_lint }

task default: :test
task lint: %i[rubocop stree:check]
