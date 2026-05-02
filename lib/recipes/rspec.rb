remove_dir 'test' if Dir.exist?('test') && template_defaults?

run 'rails generate rspec:install'
copy_file '.rspec', force: true
empty_directory_with_keep_file 'spec/factories'
gsub_file 'config/application.rb',
          /( *g\..*\n)(    end)/,
          '\1' + partial('config/application_rspec.rb', indent: 6) + '\2'

remove_comments 'spec/spec_helper.rb'
gsub_file 'spec/spec_helper.rb', %r{=begin\n(.*\n)*=end\n}, ''
format_code 'spec/spec_helper.rb'

uncomment_lines 'spec/rails_helper.rb', /config.infer_spec_type_from_file_location!/
remove_comments 'spec/rails_helper.rb'
format_code 'spec/rails_helper.rb'
gsub_file 'spec/rails_helper.rb', /^RSpec.configure/, "\n\\0"
gsub_file 'spec/rails_helper.rb', /(^  config.*)\n\n/, "\\1\n"
insert_into_file 'spec/rails_helper.rb',
                 partial('spec/rails_helper_requires.rb.tt', :prepend_nl),
                 after: "require 'rspec/rails'\n"
add_before_end 'spec/rails_helper.rb', partial('spec/rails_helper_end.rb', :prepend_nl, indent: 2)

directory 'spec/support'
copy_file_from 'vcr', 'spec/support/vcr.rb' if template_options[:vcr]

if ci?
  gsub_file '.github/workflows/ci.yml',
            %r{ *run: bin/rails db:test.*\n},
            partial('spec/.github/workflows/ci.yml', indent: 8)
end

commit 'Configure RSpec'
