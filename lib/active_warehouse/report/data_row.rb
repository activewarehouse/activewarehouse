module ActiveWarehouse #:nodoc
  module Report #:nodoc:
    class DataRow
      attr_accessor :cells
      attr_accessor :dimension_value
      
      def initialize(dimension_value, cells)
        @dimension_value = dimension_value
        @cells = cells
      end
      
    end
  end
end
