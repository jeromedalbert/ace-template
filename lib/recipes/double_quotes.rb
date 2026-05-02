gsub_file '.streerc', 'plugin/single_quotes,', ''
delete_line '.rubocop.yml', %r{Style/StringLiterals.*\n  .*}

format_code
format_quotes(
  %w[
    .irbrc
    .rubocop.yml
    config/database.yml
    config/locales/en.yml
    config/queue.yml
    app/views/layouts/*.html.erb
    lib/templates/erb/scaffold/*.html.erb
  ],
  style: :double
)

commit 'Style strings with double quotes'
