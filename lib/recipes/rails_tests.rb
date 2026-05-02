remove_comments 'test/test_helper.rb'
delete_line 'test/test_helper.rb', %r{    fixtures :all} if factory_bot?
format_code 'test/test_helper.rb'
insert_into_file 'test/test_helper.rb',
                 partial('tests/rails/test/test_helper_top.rb.tt', :prepend_nl),
                 after: %r{require ['"]rails/test_help['"]\n}
if factory_bot?
  insert_into_file 'test/test_helper.rb',
                   partial('tests/rails/test/test_helper_test_case.rb', :prepend_nl, indent: 4),
                   before: /^  end/
end

empty_directory_with_keep_file 'test/factories' if factory_bot?

copy_file 'tests/rails/test/test_helpers/controller_test_helper.rb',
          'test/test_helpers/controller_test_helper.rb'
template 'tests/helpers/dummy_data.rb.tt', 'test/test_helpers/dummy_data.rb'
template 'tests/helpers/vcr.rb.tt', 'test/test_helpers/vcr.rb' if template_options[:vcr]

commit 'Configure tests'
