ActionView::Base.field_error_proc =
  Proc.new do |html_tag, instance|
    if html_tag =~ /^<label/
      html_tag
    else
      attribute = instance.instance_variable_get(:@method_name)
      error_messages =
        instance
          .object
          .errors
          .full_messages_for(attribute)
          .map { |message| %(<div class="error-message">#{message}</div>) }

      %(
      <div class="field-with-errors">
        #{html_tag}
        <div class="error-messages">
          #{error_messages.join}
        </div>
      </div>
    ).html_safe
    end
  end
