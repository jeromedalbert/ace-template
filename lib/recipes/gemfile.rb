module SetupGemfile
  def perform
    format_quotes 'Gemfile' if single_quotes?
    run 'git add Gemfile'

    clean_up_gemfile
    set_gems
    setup_ace_template_defaults if ace_template_defaults?
  end

  private

  def clean_up_gemfile
    uncomment_lines 'Gemfile', gem_entry('image_processing') if options[:active_storage]
    uncomment_lines 'Gemfile', gem_entry('bcrypt') if template_options[:auth] == 'rails'
    remove_comments 'Gemfile'

    gsub_file 'Gemfile', /(^ *(gem|group) .*$)\n\n/, "\\1\n"
    gsub_file 'Gemfile', /group :development, :test do/, "\n\\0"
  end

  def gem_entry(gem_name)
    /gem ['"]#{gem_name}['"]/
  end

  def set_gems
    insert_into_file 'Gemfile',
                     partial('Gemfile_general_gems.rb', :append_nl),
                     before: 'group :development, :test do'
    insert_into_file 'Gemfile',
                     partial('Gemfile_dev_test_gems.rb', indent: 2),
                     after: "group :development, :test do\n"

    if tests?
      if !File.read('Gemfile').include?('group :test do')
        append_to_file 'Gemfile', "\ngroup :test do\nend\n"
      end
      insert_into_file 'Gemfile',
                       partial('Gemfile_test_gems.rb.tt', indent: 2),
                       after: "group :test do\n"
    end

    if template_options[:worker]
      delete_line 'Gemfile', /#{gem_entry('image_processing')}.*/
      delete_line 'Gemfile', /#{gem_entry('puma')}.*/
      delete_line 'Gemfile', /#{gem_entry('thruster')}.*/
    end
  end

  def setup_ace_template_defaults
    append_to_file 'Gemfile', partial('Gemfile_production_gems.rb', :prepend_nl)

    delete_line 'Gemfile', %r{  #{gem_entry('rubocop-rails-omakase')}.*} if rubocop?
    delete_line 'Gemfile', /#{gem_entry('jbuilder')}.*/ if jbuilder?

    if !Bundler.current_ruby.windows? && !Bundler.current_ruby.jruby?
      delete_line 'Gemfile', /#{gem_entry('tzinfo-data')}.*/
    end
    if Bundler.current_ruby.mri? || Bundler.current_ruby.windows?
      gsub_file 'Gemfile', /(  #{gem_entry('debug')}), platforms: .*,/, '\1,'
    end
  end
end

extend SetupGemfile
perform
