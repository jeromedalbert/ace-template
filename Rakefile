require 'bundler/setup'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'syntax_tree/rake_tasks'

#############
### Tests ###
#############

Rake::TestTask.new('test:unit') do |t|
  t.description = 'Run unit tests'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb'].exclude(/end_to_end/)
end

desc 'Run a smoke test'
task 'test:smoke' => 'default' do
  sh 'bin/test test/end_to_end/template_test.rb -n test_template', verbose: false
end

desc 'Run end-to-end tests'
task 'test:end_to_end' do
  sh 'bin/test_in_parallel test/end_to_end/*_test.rb', verbose: false
end

Rake::TestTask.new do |t|
  t.description = 'Run all tests'
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end

##############################
### Linting and formatting ###
##############################

files_to_lint = `git ls-files '*.rb' Gemfile Rakefile | grep -v files/`.split("\n")

RuboCop::RakeTask.new { |task| task.patterns = files_to_lint }
SyntaxTree::Rake::CheckTask.new { |t| t.source_files = files_to_lint }
SyntaxTree::Rake::WriteTask.new { |t| t.source_files = files_to_lint }

task lint: %i[rubocop stree:check]

desc 'Format and autocorrect all code'
task format: %i[rubocop:autocorrect stree:write]

#############
### Other ###
#############

desc 'Release template'
task 'release' do
  sh 'git push -f origin main:stable'
end

task default: %i[lint test:unit]
