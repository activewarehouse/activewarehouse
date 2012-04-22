module ActiveWarehouse
  class TimeDimensionGenerator < DimensionGenerator
    self.source_root(File.expand_path("../templates", __FILE__))
    argument :name, :type => :string, :required => false, :banner => 'DimensionName'
    
    def initialize(*args,&block)
      @name = 'time'
      super
      
      @table_name = "#{@name}_dimension"
      @class_name = "#{@name.camelize}Dimension"
      @file_name = "#{@class_name.tableize.singularize}"
    end
  end
end