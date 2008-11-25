module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    # Base module for reports.
    class AbstractReport
      attr_accessor :title
      attr_accessor :cube_name
      attr_accessor :column_dimension_name
      attr_accessor :column_hierarchy
      
      attr_accessor :column_constraints
      def column_constraints #:nodoc:
        @column_constraints ||= []
      end
      
      attr_accessor :column_stage
      attr_accessor :column_param_prefix

      attr_accessor :row_dimension_name
      attr_accessor :row_hierarchy
      
      attr_accessor :row_constraints
      def row_constraints #:nodoc:
        @row_constraints ||= []
      end
      
      attr_accessor :row_stage
      attr_accessor :row_param_prefix

      attr_accessor :fact_attributes
      
      # Array of parameters which will be passed
      attr_accessor :pass_params
      
      # A Hash of level names mapped to a method that is used to filter the 
      # available column values
      attr_accessor :column_filters
      
      # A Hash of level names mapped to a method that is used to filter the 
      # available row values
      attr_accessor :row_filters
      
      # An optional conditions String
      attr_accessor :conditions
      
      def initialize(cube_name, column_dimension_name, row_dimension_name)
        raise ArgumentError, "Cube name must be specified" unless cube_name
        @cube_name = cube_name
        
        raise ArgumentError, "Column dimension name must be specified" unless column_dimension_name
        @column_dimension_name = column_dimension_name
        
        raise ArgumentError, "Row dimension name must be specified" unless row_dimension_name
        @row_dimension_name = row_dimension_name
      end

      # Set the cube name
      def cube_name=(name)
        @cube_name = name
        @cube = nil
      end

      # Get the current cube instance
      def cube
        unless cube_name
          raise RuntimeError, "A report must specify its cube name"
        end
        
        @cube ||= begin
          cube_class = ActiveWarehouse::Cube.class_name(cube_name).constantize
          cube_class.new
        end
      end
      
      # Get the fact class
      def fact_class
        cube.class.fact_class
      end

      # Get the column dimension class
      def column_dimension_class
        @column_dimension_class ||= fact_class.dimension_class(column_dimension_name)
      end

      # Get the column hierarchy. Uses the first hierarchy in the column 
      # dimension if not specified
      def column_hierarchy
        @column_hierarchy ||= begin
          hierarchy = column_dimension_class.hierarchies.first
          return hierarchy if hierarchy
          raise RumtimeError, "#{column_dimension_class} does not appear to define any hierarchies"
        end
        @column_hierarchy = column_dimension_class.hierarchies.first if @column_hierarchy == 'NULL' # what is this for?
        @column_hierarchy
      end
      
      # Get the column prefix. Returns 'c' if not specified.
      def column_param_prefix
        @column_param_prefix ||= 'c'
      end

      # Get the row dimension class
      def row_dimension_class
        @row_dimension_class ||= fact_class.dimension_class(self.row_dimension_name)
      end
      
      # Get the row hierarchy. Uses the first hierarchy in the row dimension if
      # not specified.
      def row_hierarchy
        @row_hierarchy ||= begin
          hierarchy = row_dimension_class.hierarchies.first
          return hierarchy if hierarchy
          raise RuntimeError, "#{row_dimension_class} does not appear to define any hierarchies"
        end
        @row_hierarchy = row_dimension_class.hierarchies.first if @row_hierarchy == 'NULL' # what is this for?
        @row_hierarchy
      end
      
      # Get the row parameter prefix. Returns 'r' if not specified.
      def row_param_prefix
        @row_param_prefix ||= 'r'
      end
      
      # Get the list of displayed fact attributes. If this value is not 
      # specified then all aggregate and calculated fields will be displayed
      def fact_attributes
        @fact_attributes ||= returning Array.new do |fa|
          fact_class.aggregate_fields.each { |field| fa << field }
          fact_class.calculated_fields.each { |field| fa << field }
        end
      end
      
      def column_filters
        @column_filters ||= {}
      end
      
      def row_filters
        @row_filters ||= {}
      end
      
      def pass_params
        @pass_params ||= []
      end
      
    end
  end
end