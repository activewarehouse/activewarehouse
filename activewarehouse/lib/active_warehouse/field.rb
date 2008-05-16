module ActiveWarehouse #:nodoc:
  # Encapsulates a field.
  class Field
    # The owning class which is either a Fact or Dimension
    attr_reader :owning_class
    
    # The field name
    attr_reader :name
    
    # The field type
    attr_reader :type
    
    attr_accessor :limit
    attr_accessor :scale
    attr_accessor :precision
    
    # A Hash of options for the field
    attr_reader :field_options
    
    # +owning_class+ is the class of the table, either Fact or Dimension, that
    # this field is found in.  Must somehow subclass ActiveRecord::Base
    # +name+ is the name of this field.
    # +field_options+ is a hash of raw options from the original definition.
    # Options can include :label => a column alias or label for this field,
    # :table_alias for a table alias (useful for building queries)
    def initialize(owning_class, name, type, field_options = {})
      @owning_class = owning_class
      @name = name
      @type = type
      @field_options = field_options
      @label = field_options[:label]
      @table_alias = field_options[:table_alias]
    end
    
    # returns the :label set in field_options, or from_table_name+'_'+name.
    # Unless you have table_alias specified, then label will return table_alias+'_'+name.
    # The default label can exceed database limits, so use :label to override.
    def label
      @label ? @label : "#{table_alias || from_table_name}_#{name}"
    end
    
    # returns name of this field, matches name of the column
    def name
      @name
    end
    
    # returns rails specific column type, e.g. :float or :string
    def column_type
      @type
    end
    
    # convert the label into something we can use in a table.
    # i.e., 'Sum of Transactions' becomes 'sum_of_transactions'
    def label_for_table
      label.gsub(/ /, '_').downcase
    end
    
    # returns the table name that has this fact column
    def from_table_name
      owning_class.table_name
    end
    
    # returns a table alias or if none set just the table name
    def table_alias
      @table_alias || from_table_name
    end
    
    # Get a display string for the field. Delegates to label.
    def to_s
      label
    end
    
  end
end