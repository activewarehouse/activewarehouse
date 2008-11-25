module ActiveWarehouse #:nodoc: 
  module Report #:nodoc:
    class DataCell
      
      attr_accessor :column_dimension_value
      attr_accessor :row_dimension_value
      attr_accessor :fact_attribute
      attr_accessor :raw_value
      attr_accessor :value
      
      def initialize(column_dimension_value, row_dimension_value, fact_attribute, raw_value, value)
        @column_dimension_value = column_dimension_value 
        @row_dimension_value = row_dimension_value
        @fact_attribute = fact_attribute 
        @raw_value = raw_value
        @value = value
      end
      
      def key
        "#{column_dimension_value}_#{fact_attribute.label}".gsub(' ', '_').downcase
      end     
    end
  end
end