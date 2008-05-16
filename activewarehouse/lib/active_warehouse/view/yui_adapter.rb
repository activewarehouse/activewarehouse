module ActiveWarehouse::View
  module YuiAdapter
    def yui_column_definitions(table_view)
      columns = [{:key => 'row_dimension_key', :label => table_view.row_dimension.hierarchy_level.to_s.humanize.titleize, :sortable => true}]
      table_view.column_dimension.values.each do |col_dim_value|
        if table_view.column_dimension.has_children?
          col_label = %Q{<a href="#{url_for(table_view.column_link(col_dim_value))}" onclick="location.href=this.href;" class="yui-dt-link">#{col_dim_value}</a>}
        else
          col_label = col_dim_value
        end
        column = {:label => col_label}
        column[:children] = []
        table_view.fact_attributes.each do |fact_attribute|
					child_data = {:sortable => true}
          child_data[:label] = fact_attribute.label.humanize.titleize

					format = table_view.report.format[fact_attribute.name.to_sym]
          if format && format.is_a?(Symbol)
						child_data[:formatter] = format
          end
          child_data[:key] = "#{col_dim_value}_#{fact_attribute.label}".gsub(' ', '_').downcase
          column[:children] << child_data
        end	
        columns << column
      end
      columns
    end

    def yui_data_rows(table_view)
      data_rows = []
  		table_view.data_rows.each do |data_row|
  			data = {}
  			data[:row_dimension_key] = link_to_if(table_view.row_dimension.has_children?, data_row.dimension_value, table_view.row_link(data_row.dimension_value))
  			data[:row_dimension_label] = data_row.dimension_value

  	    data_row.cells.each_with_index do |cell, index| # aggregated facts
					value = cell.raw_value
					format = table_view.report.format[cell.fact_attribute.name.to_sym]
          if format && format.is_a?(Proc)
						value = format.call(cell.raw_value)
          end	
	
  				value = link_to_if((table_view.report.link_cell && column_dimension.has_children? && row_dimension.has_children?), value, 
 						table_view.cell_link(cell.column_dimension_value,data_row.dimension_value)
 					)
 					data[cell.key.to_sym] = value
  	    end
  			data_rows << data
  		end
  		data_rows
    end

    def yui_totals_row(table_view)
      x = ::Builder::XmlMarkup.new
  		x.tr() do |x|
  			x.td do 
					x.div(:class => "yui-dt-liner"){ |x| x << "Grand Totals"}
				end
  			table_view.data_columns.each_with_index do |column, index|
        	x.td do |x|
  					x.div(:class => "yui-dt-liner"){ |x| x << table_view.column_total(index)}
  				end
  			end		
  		end
  		x.target!
    end
  end
end