require 'rails/generators/rails/resource_route/resource_route_generator'

class Rails::ResourceRouteCustomGenerator < Rails::Generators::ResourceRouteGenerator
  alias_method :original_add_resource_route, :add_resource_route

  def add_resource_route
    return if options[:actions].present?
    routes = File.read('config/routes.rb')
    return super if namespaced_route? && routes.include?(namespace_components.first)

    @first_paragraphs, @last_paragraph =
      routes.match(/Rails.application.routes.draw do\n(.*)\n\n(.*)end/m).captures
    return super if @first_paragraphs.nil?

    add_resource_route_before_last_paragraph
  end

  private

  def namespaced_route?
    regular_class_path.any?
  end

  def namespace_components
    regular_class_path
  end

  def add_resource_route_before_last_paragraph
    blank_line_before_route =
      namespaced_route? || !@first_paragraphs.include?("\n\n") || @first_paragraphs.end_with?('end')

    File.write('config/routes.rb', "Rails.application.routes.draw do\nend")
    original_add_resource_route

    insert_into_file 'config/routes.rb',
                     "#{@first_paragraphs}\n#{"\n" if blank_line_before_route}",
                     after: "Rails.application.routes.draw do\n",
                     verbose: false
    insert_into_file 'config/routes.rb', "\n#{@last_paragraph}", before: /^end/, verbose: false
  end
end
