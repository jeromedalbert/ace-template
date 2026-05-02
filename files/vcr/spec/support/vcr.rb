VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Prevent writing sensitive data to cassette files
  # config.filter_sensitive_data('<MY_API_KEY>') { ENV['MY_API_KEY'] }

  # Pretty print JSON body in cassettes files
  # Reference:
  #   - https://github.com/vcr/vcr/pull/147
  #   - https://gist.github.com/mislav/26edfe7669cc7b85e164
  config.before_record do |i|
    type = Array(i.response.headers['Content-Type']).join(',').split(';').first
    if type =~ %r{[/+]json$} || type == 'text/javascript'
      begin
        data = JSON.parse i.response.body
      rescue StandardError
        warn "VCR: JSON parse error for Content-type #{type}"
      else
        i.response.body = JSON.pretty_generate data
        i.response.update_content_length_header
      end
    end
  end
end
