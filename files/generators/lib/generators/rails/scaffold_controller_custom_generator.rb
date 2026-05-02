require 'rails/generators/rails/scaffold_controller/scaffold_controller_generator'

class Rails::ScaffoldControllerCustomGenerator < Rails::Generators::ScaffoldControllerGenerator
  source_root Rails::Generators::ScaffoldControllerGenerator.source_root

  def clean_up_controller
    file =
      File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")

    gsub_file file, /^ *#.*\n/, ''
    gsub_file file, ', status: :see_other', '', verbose: false
    gsub_file file, ':unprocessable_entity', ':unprocessable_content', verbose: false
    gsub_file file, 'set_', 'load_', verbose: false
    gsub_file file, '.destroy!', ".destroy!\n", verbose: false
  end
end
