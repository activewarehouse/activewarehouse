module ActiveWarehouse #:nodoc:
  module Report #:nodoc:
    class Dimension
      
      attr_reader :dimension_class
      attr_reader :name
      attr_reader :hierarchy
      attr_reader :hierarchy_name
      attr_reader :filters
      attr_reader :stage
      attr_reader :hierarchy_length
      attr_reader :hierarchy_level
      attr_reader :param_prefix
      
      def initialize(dimension_type, report, params = {})
        
        @dimension_class = report.send("#{dimension_type}_dimension_class")
        @name = report.send("#{dimension_type}_dimension_name")
        @hierarchy_name = report.send("#{dimension_type}_hierarchy")
        @filters = report.send("#{dimension_type}_filters")
        @param_prefix = report.send("#{dimension_type}_param_prefix")
        @stage = (params[:stage] || report.send("#{dimension_type}_stage")).to_i
        
        @hierarchy = @dimension_class.hierarchy(@hierarchy_name)
        @hierarchy_length = @hierarchy.length
        @hierarchy_level = @hierarchy[@stage]
        @params = params
      end
      
      def self.column(report, params = {})
        Dimension.new(:column, report, params)
      end

      def self.row(report, params = {})
        Dimension.new(:row, report, params)
      end

      def query_filters
        param_filters = {}
        @params[:ancestors].each do |key, value|
          param_filters["#{name}.#{key}"] = value
        end   
        param_filters
      end
      
      def values
        filters[hierarchy_level].blank? ? available_values : available_values & filters[hierarchy_level]
      end
      
      def ancestors
        (0..stage-1).map do |s| 
          @params[:ancestors][hierarchy[s].to_s]
        end.compact
      end

      def has_children?
        stage < hierarchy_length - 1
      end

      def available_values
        dimension_class.available_child_values(hierarchy_name, ancestors).map(&:to_s)
      end
    end
  end
end
