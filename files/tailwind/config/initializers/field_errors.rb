ActionView::Base.field_error_proc = ->(html_tag, instance) do
  if html_tag.match?(/^<label/)
    html_tag
  else
    html_tag = html_tag.sub('class="', 'class="border border-red-500 ')
    attribute = instance.instance_variable_get(:@method_name)
    error_messages =
      instance
        .object
        .errors
        .full_messages_for(attribute)
        .map { |message| %(<li class="text-red-500">#{message}</li>) }

    %(
      #{html_tag}
      <ul class="mt-2">
        #{error_messages.join}
      </ul>
    ).html_safe
  end
end
