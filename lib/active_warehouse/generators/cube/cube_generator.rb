class CubeGenerator < Rails::Generator::NamedBase
  attr_accessor :file_name
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    @name = @name.underscore
    @table_name = "#{@name}_cube"
    @class_name = "#{@name.camelize}Cube"
    @file_name = "#{@class_name.tableize.singularize}"
  end
  
  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions class_path, "#{class_name}", "#{class_name}Test"
      
      # Create required directories if necessary
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      
      # Generate the files
      m.template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
    end
  end

end