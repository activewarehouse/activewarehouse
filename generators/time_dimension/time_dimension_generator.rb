class TimeDimensionGenerator < DimensionGenerator
  attr_accessor :file_name
  
  default_options :skip_migration => false
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    @name = 'date'
    @table_name = "#{@name}_dimension"
    @class_name = "#{@name.camelize}Dimension"
    @file_name = "#{@class_name.tableize.singularize}"
  end
end