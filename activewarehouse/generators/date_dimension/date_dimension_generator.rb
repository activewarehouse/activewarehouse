class DateDimensionGenerator < DimensionGenerator
  attr_accessor :file_name
  attr_accessor :include_fiscal_year
  
  default_options :skip_migration => false
  
  def initialize(runtime_args, runtime_options = {})
    super
    
    @name = 'date'
    @table_name = "#{@name}_dimension"
    @class_name = "#{@name.camelize}Dimension"
    @file_name = "#{@class_name.tableize.singularize}"
    @include_fiscal_year = true # TODO: accept a runtime option to set this
  end
end