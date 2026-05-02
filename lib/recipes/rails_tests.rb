remove_comments 'test/test_helper.rb'
delete_line 'test/test_helper.rb', %r{    fixtures :all}
format_code 'test/test_helper.rb'
insert_into_file 'test/test_helper.rb',
                 partial('tests/rails/test/test_helper_top.rb.tt', :prepend_nl),
                 after: "require 'rails/test_help'\n"
insert_into_file 'test/test_helper.rb',
                 partial('tests/rails/test/test_helper_test_case.rb', :prepend_nl, indent: 4),
                 before: /^  end/
append_to_file 'test/test_helper.rb', partial('tests/rails/test/test_helper_end.rb', :prepend_nl)

empty_directory_with_keep_file 'test/factories'

copy_file 'tests/rails/test/test_helpers/controller_test_helper.rb',
          'test/test_helpers/controller_test_helper.rb'
template 'tests/helpers/dummy_data.rb.tt', 'test/test_helpers/dummy_data.rb'
template 'tests/helpers/vcr.rb.tt', 'test/test_helpers/vcr.rb' if template_options[:vcr]

commit 'Configure tests'
