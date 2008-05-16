module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    # Base module for reports.
    module AbstractReport
      
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

      # Set the cube name
      def cube_name=(name)
        write_attribute(:cube_name, name)
        @cube = nil
      end

      # Get the current cube instance
      def cube
        if @cube.nil?
          cube_class = ActiveWarehouse::Cube.class_name(self.cube_name).constantize
          @cube = cube_class.new
        end
        @cube
      end
      
      # Get the fact class
      def fact_class
        cube.class.fact_class
      end

      # Get the column dimension class
      def column_dimension_class
        @column_dimension_class ||= ActiveWarehouse::Dimension.class_name(self.column_dimension_name).constantize
      end

      # Get the column hierarchy. Uses the first hierarchy in the column 
      # dimension if not specified
      def column_hierarchy
        ch = read_attribute(:column_hierarchy)
        if ch.nil? || ch == 'NULL'
          column_dimension_class.hierarchies.first
        else
          ch
        end
      end
      
      # Get the column prefix. Returns 'c' if not specified.
      def column_param_prefix
        read_attribute(:column_param_prefix) || 'c'
      end

      # Get the row dimension class
      def row_dimension_class
        @row_dimension_class ||= ActiveWarehouse::Dimension.class_name(
          self.row_dimension_name).constantize
      end
      
      # Get the row hierarchy. Uses the first hierarchy in the row dimension if
      # not specified
      def row_hierarchy
        read_attribute(:row_hierarchy) || row_dimension_class.hierarchies.first
      end
      
      # Get the row parameter prefix. Returns 'r' if not specified.
      def row_param_prefix
        read_attribute(:row_param_prefix) || 'r'
      end
      
      # Get the list of displayed fact attributes. If this value is not 
      # specified then all aggregate and calculated fields will be displayed
      def fact_attributes
        return read_attribute(:fact_attributes) if read_attribute(:fact_attributes)
        fa = []
        fact_class.aggregate_fields.each { |field| fa << field }
        fact_class.calculated_fields.each { |field| fa << field }
        fa
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
      
      protected
      # Callback which is invoked on each object returned from a call to the object's find method.
      def after_find
        from_storage
      end
      
      # Converts values for all columns which can store symbol values into strings. This is used to store 
      # the data in the database as a string rather than a YAML representation
      def to_storage
        symbol_attributes.each do |name|
          self[name] = self[name].to_s if self[name]
        end
        list_attributes.each do |name|
          self[name] = self[name].join(',') if self[name]
        end
        symbolized_list_attributes.each do |name|
          self[name] = self[name].join(',') if self[name]
        end
      end
      
      # Converts values for all columns which store strings in the database to symbols.
      def from_storage
        symbol_attributes.each do |name|
          self[name] = self[name].to_sym if self[name]
        end
        list_attributes.each do |name|
          self[name] = self[name].split(/,/) if self[name]
        end
        symbolized_list_attributes.each do |name|
          self[name] = self[name].split(/,/).collect { |v| v.to_sym } if self[name]
        end
      end
      
      # Attributes which should contain a symbol
      def symbol_attributes
        %w(cube_name column_dimension_name column_hierarchy row_dimension_name row_hierarchy)
      end
      
      # Attributes which should contain a list of strings
      def list_attributes
        %w(column_constraints row_constraints)
      end
      
      # Attributes which should contain a list of symbols
      def symbolized_list_attributes
        %w(fact_attributes)
      end
      
    end
  end
end