require 'rails_helper'

<% module_namespacing do -%>
describe <%= controller_class_name %>Controller do
  let(:<%= singular_table_name %>) { create(:<%= singular_table_name %>) }

  describe '#index' do
    before { get :index }

    it { should respond_with :ok }
  end

  describe '#show' do
    before { get :show, params: { id: <%= singular_table_name %>.id } }

    it { should respond_with :ok }
  end

  describe '#new' do
    before { get :new }

    it { should respond_with :ok }
  end

  describe '#edit' do
    before { get :edit, params: { id: <%= singular_table_name %>.id } }

    it { should respond_with :ok }
  end

  describe '#create' do
    context 'when params are invalid' do
      before do
        post :create, params: { <%= singular_table_name %>: { <%= attributes.first&.column_name || 'my_attribute' %>: '' } }
      end

      it { should respond_with :unprocessable_content }
    end

    context 'when params are valid' do
      before do
        post :create, params: { <%= singular_table_name %>: attributes_for(:<%= singular_table_name %>) }
      end

      it { should redirect_to <%= singular_table_name %>_path(<%= class_name %>.last.id) }
    end
  end

  describe '#update' do
    context 'when params are invalid' do
      before do
        patch :update, params: {
          id: <%= singular_table_name %>.id, <%= singular_table_name %>: { <%= attributes.first&.column_name || 'my_attribute' %>: '' }
        }
      end

      it { should respond_with :unprocessable_content }
    end

    context 'when params are valid' do
      before do
        patch :update, params: {
          id: <%= singular_table_name %>.id, <%= singular_table_name %>: attributes_for(:<%= singular_table_name %>)
        }
      end

      it { should redirect_to <%= singular_table_name %>_path(<%= class_name %>.last.id) }
    end
  end

  describe '#destroy' do
    before { delete :destroy, params: { id: <%= singular_table_name %>.id } }

    it { should redirect_to <%= index_helper %>_path }
  end
end
<% end -%>
