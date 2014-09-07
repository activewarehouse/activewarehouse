module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    # Base module for reports.
    module AbstractReport
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


      def initialize(attributes = {})
        attributes.each do |name, value|
          send("#{name}=", value)
        end
      end


      # Set the cube name
      def cube_name=(name)
        @cube_name = name
        @cube = nil
      end

      # Get the current cube instance
      def cube
        @cube ||= 
          begin
            cube_class = ActiveWarehouse::Cube.class_name(self.cube_name).constantize
            cube_class.new
          end
      end

      # Get the fact class
      def fact_class
        cube.class.fact_class
      end

      # Get the column dimension class
      def column_dimension_class
        @column_dimension_class ||= fact_class.dimension_class(self.column_dimension_name)
      end

      # Get the column hierarchy. Uses the first hierarchy in the column 
      # dimension if not specified
      def column_hierarchy
        ch = @column_hierarchy
        if ch.nil? || ch == 'NULL'
          column_dimension_class.hierarchies.first
        else
          ch
        end
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
      # not specified
      def row_hierarchy
        @row_hierarchy ||= row_dimension_class.hierarchies.first
      end

      # Get the row parameter prefix. Returns 'r' if not specified.
      def row_param_prefix
        @row_param_prefix ||= 'r'
      end

      # Get the list of displayed fact attributes. If this value is not 
      # specified then all aggregate and calculated fields will be displayed
      def fact_attributes
        @fact_attributes ||= Array.new.tap do |fa|
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
