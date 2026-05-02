require 'test_helper'

<% module_namespacing do -%>
class <%= controller_class_name %>ControllerTest < ActionDispatch::IntegrationTest
  test 'index' do
    get <%= index_helper(type: :path) %>

    assert_response :ok
  end

  test 'show' do
    create_<%= singular_table_name %>

    get <%= show_helper(type: :path) %>

    assert_response :ok
  end

  test 'new' do
    get <%= new_helper(type: :path) %>

    assert_response :ok
  end

  test 'edit' do
    create_<%= singular_table_name %>

    get <%= edit_helper(type: :path) %>

    assert_response :ok
  end

  test 'create' do
    post <%= index_helper(type: :path) %>, params: { <%= singular_table_name %>: attributes_for(:<%= singular_table_name %>) }

    assert_redirected_to <%= show_helper("#{class_name}.last") %>
  end

  test 'create with invalid params' do
    post <%= index_helper(type: :path) %>, params: { <%= singular_table_name %>: { <%= attributes.first&.column_name || 'my_attribute' %>: '' } }

    assert_response :unprocessable_content
  end

  test 'update' do
    create_<%= singular_table_name %>

    patch <%= show_helper(type: :path) %>, params: { <%= singular_table_name %>: attributes_for(:<%= singular_table_name %>) }

    assert_redirected_to <%= show_helper %>
  end

  test 'update with invalid credentials' do
    create_<%= singular_table_name %>

    patch <%= show_helper(type: :path) %>, params: { <%= singular_table_name %>: { <%= attributes.first&.column_name || 'my_attribute' %>: '' } }

    assert_response :unprocessable_content
  end

  test 'destroy' do
    create_<%= singular_table_name %>

    delete <%= show_helper(type: :path) %>

    assert_redirected_to <%= index_helper(type: :path) %>
  end

  private

  def create_<%= singular_table_name %>
    @<%= singular_table_name %> = create(:<%= singular_table_name %>)
  end
end
<% end -%>
