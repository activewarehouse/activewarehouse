# Source file which defines the ActiveWarehouse::Aggregate module and imports
# the aggregate implementations.

module ActiveWarehouse #:nodoc:
  # This module contains classes which handle aggregation of cube data using
  # various algorithms
  module Aggregate
    # Base class for aggregate implementations
    class Aggregate
      
      # Reader for the cube class
      attr_reader :cube_class
      
      # Initialize the aggregate for the given cube class
      def initialize(cube_class)
        @cube_class = cube_class
      end
      
      protected
      # Get the connection to use for SQL execution
      def connection
        cube_class.connection
      end
      
      # Convenience accessor to get the cube's fact class. Delegates to the
      # cube class.
      def fact_class
        cube_class.fact_class
      end
      
      # Parse the query args and return an options hash.
      def parse_query_args(*args)
        options = {}
        if args.length == 1
          options = args[0]
        elsif args.length >= 4
          options[:column_dimension_name] = args[0]
          options[:column_hierarchy_name] = args[1]
          options[:row_dimension_name] = args[2]
          options[:row_hierarchy_name] = args[3]
          options[:conditions] = args[4] if args.length >= 5
          options[:cstage] = args[5] if args.length >= 6
          options[:rstage] = args[6] if args.length >= 7
          options[:filters] = args[7] if args.length >= 8
          options.merge!(args[8]) if args.length >= 9
        else
          raise ArgumentError, "The query method accepts either 1 Hash (new style) or 4 to 8 arguments (old style)"
        end
        options
      end
    end
  end
end

require 'active_warehouse/aggregate/no_aggregate'
require 'active_warehouse/aggregate/dwarf_common'
require 'active_warehouse/aggregate/dwarf_aggregate'
require 'active_warehouse/aggregate/pid_aggregate'