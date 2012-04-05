module ActiveWarehouse
  class CubeGenerator < Rails::Generators::NamedBase
    self.source_root(File.expand_path("../templates", __FILE__))

    argument :name, :type => :string, :required => true, :banner => 'CubeName'
    check_class_collision
    check_class_collision :suffix => "Test"
    
    def initialize(*args,&block)
      super
    
      @name = @name.underscore
      @table_name = "#{@name}_cube"
      @class_name = "#{@name.camelize}Cube"
      @file_name = "#{@class_name.tableize.singularize}"
    end
 
   def create_files
     template 'model.rb', "app/models/#{file_name}.rb"
     template 'unit_test.rb',"test/unit/#{file_name}_test.rb"
   end
   
  end
end