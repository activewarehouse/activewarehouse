module ActiveWarehouse #:nodoc:
  module Aggregate #:nodoc:
    # Implementation of a Partitioning and Inserting Dwarf algorithm as defined
    # in http://www.zju.edu.cn/jzus/2005/A0506/A050608.pdf
    class PidAggregate < Aggregate
      include DwarfCommon
      
      # Initialize the aggregate
      def initialize(cube_class)
        super
      end
      
      # Populate the aggregate
      def populate
        create_dwarf_cube(sorted_facts)
      end
      
      # Query the aggregate
      def query(*args)
        options = parse_query_args(*args)
      end
      
      def create_dwarf_cube(sorted_facts)
        
      end

    end
  end
end