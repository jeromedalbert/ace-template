remove_dir 'test' if Dir.exist?('test')

run 'rails generate rspec:install'
copy_file '.rspec', force: true
empty_directory_with_keep_file 'spec/factories' if factory_bot?
gsub_file 'config/application.rb',
          /( *g\..*\n)(    end)/,
          '\1' + partial('tests/rspec/config/application.rb', indent: 6) + '\2'

remove_comments 'spec/spec_helper.rb'
gsub_file 'spec/spec_helper.rb', %r{=begin\n(.*\n)*=end\n}, ''
format_code 'spec/spec_helper.rb'

uncomment_lines 'spec/rails_helper.rb', /config.infer_spec_type_from_file_location!/
remove_comments 'spec/rails_helper.rb'
format_code 'spec/rails_helper.rb'
gsub_file 'spec/rails_helper.rb', /^RSpec.configure/, "\n\\0"
gsub_file 'spec/rails_helper.rb', /(^  config.*)\n\n/, "\\1\n"
insert_into_file 'spec/rails_helper.rb',
                 partial('tests/rspec/spec/rails_helper_requires.rb.tt', :prepend_nl),
                 after: %r{require ['"]rspec/rails['"]\n}
if template_options[:rails_fixtures]
  insert_into_file 'spec/rails_helper.rb',
                   "  config.global_fixtures = :all\n",
                   after: /config.use_transactional_fixtures = .*\n/
end
add_before_end 'spec/rails_helper.rb',
               partial('tests/rspec/spec/rails_helper_end.rb.tt', :prepend_nl, indent: 2)

directory 'tests/rspec/spec/support', 'spec/support'
template 'tests/helpers/dummy_data.rb.tt', 'spec/support/dummy_data.rb'
template 'tests/helpers/vcr.rb.tt', 'spec/support/vcr.rb' if template_options[:vcr]

if ci?
  gsub_file '.github/workflows/ci.yml',
            %r{ *run: bin/rails db:test.*\n},
            partial('tests/rspec/spec/.github/workflows/ci.yml', indent: 8)
  delete_line '.github/workflows/ci.yml', /\n  system-test:.*/m

  if File.exist?('config/ci.rb')
    delete_line 'config/ci.rb', /.*Tests: System.*/
    gsub_file 'config/ci.rb', 'bin/rails test', 'bin/rspec'
  end
end

commit 'Configure RSpec'
