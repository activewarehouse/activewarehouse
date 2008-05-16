module ActiveWarehouse
	module Report

		class Dimension
			
			attr_reader :dimension_class, :name, :hierarchy, :hierarchy_name, :filters, :stage, :hierarchy_length, :hierarchy_level, :param_prefix
			
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
		    col_path = []
		    0.upto(stage - 1) do |s| 
		      p = @params[:ancestors]["#{dimension_class.hierarchy(hierarchy_name)[s]}"]
		      col_path << p unless p.nil?
		    end
				col_path
			end

			def has_children?
				stage < hierarchy_length - 1
			end

			# TODO Move to dimension
			# looks like we could give it all the values for each level to select on before invoking the method on the instance method
			# maybe have a values call on this dimension object that digests the params and have the original dimension object do the select itself
		  def available_values
		    # Construct the column find options
		    find_options = {}
		    group_by = []
		    conditions_sql = []
		    conditions_args = []
		    @stage.downto(0) do |stage|
		      level = dimension_class.hierarchy(hierarchy_name)[stage]
		      group_by << level
		      unless stage == @stage
		        conditions_sql << "#{level} = '#{@params[:ancestors][level.to_s]}'" # TODO protect against injection
		      else
		        find_options[:select] = level
		      end
		    end

		    find_options[:conditions] = nil
		    find_options[:conditions] = conditions_sql.join(" AND ") if conditions_sql.length > 0
		    find_options[:group] = find_options[:order] = group_by.join(',')

		    q = "SELECT #{find_options[:select]} FROM #{dimension_class.table_name}"
		    q << " WHERE #{find_options[:conditions]}" if find_options[:conditions]
		    q << " GROUP BY #{find_options[:group]}" if find_options[:group]
		    q << " ORDER BY #{find_options[:order]}" if find_options[:order]

		    puts "query: #{q}"

		    dimension_class.connection.select_values(q)
		  end
		end
	end
end
