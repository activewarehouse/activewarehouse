module ActiveWarehouse
  class DateDimensionGenerator < DimensionGenerator
    attr_accessor :include_fiscal_year
    self.source_root(File.expand_path("../templates", __FILE__))
    argument :name, :type => :string, :required => false, :banner => 'DimensionName'
  
    def initialize(*args,&block)
      @name = 'date'
      super
    
      @table_name = "#{@name}_dimension"
      @class_name = "#{@name.camelize}Dimension"
      @file_name = "#{@class_name.tableize.singularize}"
      @include_fiscal_year = true # TODO: accept a runtime option to set this
    end
  end
end