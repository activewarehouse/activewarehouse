module ActiveWarehouse #:nodoc:
  module Aggregate #:nodoc:
    # Common methods for use inside dwarf implementations
    module DwarfCommon
      # Get the dimension order, defaults to sorting from highest cardinality to lowest
      def dimension_order
        @dimension_order ||= cube_class.dimension_classes.sort { |a, b| a.count <=> b.count }.reverse
      end
      
      # Set the dimension order
      def dimension_order=(dimensions)
        @dimension_order = dimensions
      end
      
      # Get the sorted fact rows for this cube, sorted by dimensions returned from dimension_order.
      def sorted_facts
        #puts "dimension order: #{dimension_order.inspect}"
        # Determine the dimension to order by (high cardinality)
        order_by = dimension_order.collect { |d| cube_class.fact_class.foreign_key_for(d) }.join(",")
        
        # Get the sorted fact table
        # TODO: determine if querying with select_all will bring the entire result set into memory
        sql = "SELECT * FROM #{cube_class.fact_class.table_name} ORDER BY #{order_by}"
        cube_class.connection.select_all(sql)
      end
      
      # Create a tuple from a row
      def create_tuple(row)
        fact_class = cube_class.fact_class
        tuple = []
        dimension_order.each do |d|
          column_name = fact_class.foreign_key_for(d)
          tuple << fact_class.columns_hash[column_name].type_cast(row[column_name])
        end
        fact_class.aggregate_fields.each do |f|
          tuple << fact_class.columns_hash[f.to_s].type_cast(row[f.to_s])
        end
        #puts "tuple: #{tuple.inspect}"
        tuple
      end
      
    end
  end
end