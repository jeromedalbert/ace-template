uncomment_lines 'Gemfile', /gem "image_processing"/ if options[:active_storage]
uncomment_lines 'Gemfile', /gem "bcrypt"/ if template_options[:auth] == 'rails'
remove_comments 'Gemfile'
gsub_file 'Gemfile', /(^ *(gem|group) .*$)\n\n/, "\\1\n"
gsub_file 'Gemfile', /group :development, :test do/, "\n\\0"

insert_into_file 'Gemfile',
                 partial('Gemfile_general_gems.rb', :append_nl),
                 before: 'group :development, :test do'
insert_into_file 'Gemfile',
                 partial('Gemfile_dev_test_gems.rb', indent: 2),
                 after: "group :development, :test do\n"
if !File.read('Gemfile').include?('group :test do')
  append_to_file 'Gemfile', "\ngroup :test do\nend\n"
end
insert_into_file 'Gemfile', partial('Gemfile_test_gems.rb.tt', indent: 2), after: "group :test do\n"
append_to_file 'Gemfile', partial('Gemfile_production_gems.rb', :prepend_nl)

gsub_file 'Gemfile', %r{  gem "rubocop-rails-omakase".*\n}, '' if rubocop?
delete_line 'Gemfile', /gem "jbuilder".*/ if template_defaults?
if template_options[:worker]
  delete_line 'Gemfile', /gem "image_processing".*/
  delete_line 'Gemfile', /gem "puma".*/
  delete_line 'Gemfile', /gem "thruster".*/
end

if !Bundler.current_ruby.windows? && !Bundler.current_ruby.jruby?
  delete_line 'Gemfile', /gem "tzinfo-data".*/
end
if Bundler.current_ruby.mri? || Bundler.current_ruby.windows?
  gsub_file 'Gemfile', /(  gem "debug"), platforms: .*,/, '\1,'
end
