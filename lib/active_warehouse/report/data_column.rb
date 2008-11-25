module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    class DataColumn
      
      attr_accessor :dimension_value
      attr_accessor :fact_attribute
      attr_accessor :label
      
      def initialize(label, dimension_value, fact_attribute)
        @label = label
        @dimension_value = dimension_value
        @fact_attribute = fact_attribute
      end
      
      def key
        "#{dimension_value}_#{fact_attribute.label}".gsub(' ', '_').downcase
      end
    end
  end
end
