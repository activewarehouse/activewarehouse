module ActiveWarehouse #:nodoc:
  module View #:nodoc:
    class TableView
      include AbstractView

      attr_reader :query_result
      attr_reader :fact_attributes
      attr_reader :data_columns
      attr_reader :row_crumbs
      attr_reader :column_crumbs
      attr_reader :with_totals
      attr_reader :sortable
                  
      attr_accessor :ignore_columns
      
      def initialize(report, params, options = {})
        super
        @with_totals = options.has_key?(:with_totals)
        @sortable = options.has_key?(:sortable)
        @ignore_columns = options.has_key?(:ignore_columns) ? options[:ignore_columns] : []
        @column_crumbs = ColumnCrumb.gather(@column_dimension, @current_params)
        @row_crumbs = RowCrumb.gather(@row_dimension, @current_params)
        @query_result = execute_query
        
        @fact_attributes = report.fact_attributes.map do |fact_attribute|
          case fact_attribute
          when Symbol, String
            fact_attribute = report.fact_class.field_for_name(fact_attribute.to_s.dup)
            raise "Field name #{fact_attribute} not defined in the fact #{report.fact_class}" if fact_attribute.nil?
            fact_attribute
          else
            fact_attribute  
          end     
        end
      end
      
      def execute_query
        report.cube.query_row_and_column(row_dimension, column_dimension,
          :conditions => report.conditions )
      end

      def column_total(column_index)
        column = data_columns[column_index]
        return "" unless column
        column_attribute_key = column.fact_attribute.name.to_sym        
        return "" if ignore_columns.include?(column_attribute_key)
        total = 0
        data_rows.each do |row|
          value = row.cells[column_index].raw_value
          if value.is_a? Numeric
            total += value
          end 
        end
          
        formatted_value = format_data(column_attribute_key,total)
        # formatted_value = format_data(column.fact_attribute.name.to_sym,total)
      end
      
      def data_columns
        @data_columns ||= []
        return @data_columns unless @data_columns.empty?
        if column_dimension
          column_dimension.values.each do |dimension_value|
            @fact_attributes.each do |fact_attribute|
              @data_columns << ActiveWarehouse::Report::DataColumn.new(fact_attribute.label.humanize.titleize, dimension_value, fact_attribute)
            end         
          end
        end
        @data_columns
      end
        
      def data_rows
        @data_rows ||= []
        return @data_rows unless @data_rows.empty?
        if row_dimension
          columns = self.data_columns
          row_dimension.values.each do |row_dimension_value|
            cells = []
            columns.each do |column|
              cells << data_cell(column.fact_attribute, column.dimension_value, row_dimension_value)
            end         
            @data_rows << ActiveWarehouse::Report::DataRow.new(row_dimension_value, cells)
          end
        end
        @data_rows
      end
    
      def data_cell(fact_attribute, column_dimension_value, row_dimension_value)
        value = ''
        raw_value = nil
        case fact_attribute
        when ActiveWarehouse::AggregateField
          raw_value = query_result.value(row_dimension_value, column_dimension_value, fact_attribute.label)
        when ActiveWarehouse::CalculatedField
          raw_value = fact_attribute.calculate(query_result.values(row_dimension_value, column_dimension_value))
        end
        
        formatted_value = format_data(fact_attribute.name.to_sym,raw_value)
        ActiveWarehouse::Report::DataCell.new(column_dimension_value, row_dimension_value, fact_attribute, raw_value, formatted_value)  
      end
    
      def column_link(column_dimension_value)
        current_params.merge({:cstage => column_dimension.stage + 1, 
          "#{column_dimension.param_prefix}_#{column_dimension.hierarchy_level}" => column_dimension_value})
      end   
      
      def row_link(row_dimension_value)
        current_params.merge({:rstage => row_dimension.stage + 1, 
          "#{row_dimension.param_prefix}_#{row_dimension.hierarchy_level}" => row_dimension_value})
      end
      
      def cell_link(column_dimension_value,row_dimension_value)
        current_params.merge({:rstage => row_dimension.stage + 1, :cstage => column_dimension.stage + 1, 
          "#{column_dimension.param_prefix}_#{column_dimension.hierarchy_level}" => column_dimension_value,
          "#{row_dimension.param_prefix}_#{row_dimension.hierarchy_level}" => row_dimension_value})
      end
      
      def sortable?
        @sortable
      end
      
      def with_totals?
        @with_totals
      end
      
      def format_data(field, raw_value)
        format = report.format[field]
        if format && format.is_a?(Proc)
            value = format.call(raw_value)
        elsif format == :currency 
            value = sprintf("$%.2f", raw_value)
        else
          value = raw_value.to_s
        end   
      end
    end
    
  end
end
