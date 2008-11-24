# Helper module for rendering reports.
module ReportHelper
  # include ActiveWarehouse::Report::YuiAdapter
  
  # UNSUPPORTED METHOD. Please use render_report_from instead.
  # * <tt>report</tt>: The report instance
  # * <tt>html_options</tt>: HTML options
  def render_report(report, html_options={})
    raise "Unsupported Render Method.  Please use render_report_from instead."
  end
  
  def render_report_from(table_view, html_options = {})
    
    # must use YUI if sorting is desired
    if table_view.sortable? 
      raise "Sortable requires Yui4Rails plugin." unless defined? Yui4Rails
      
      html_options[:report_id] ||= 'yui_table'
      
      data_table = Yui4Rails::Widgets::DataTable.new(
        html_options[:report_id], 
        yui_column_definitions(table_view), 
        yui_data_rows(table_view), 
        table_view.with_totals? ? yui_totals_row(table_view) : ""
      )
      
      return data_table.render
    end
    
    # ... else render in html
    report = table_view.report
    column_dimension = table_view.column_dimension
    row_dimension = table_view.row_dimension

    table_attributes = {}
    table_attributes[:class] = html_options[:report_class] ||= 'report'

    # build the XHTML
    x = ::Builder::XmlMarkup.new(:indent => 2)
    x.table(table_attributes) do |x|
  
      x.tr do |x| # column dimension
        x.th
        column_dimension.values.each do |col_dim_value|
          x.th({:colspan => report.fact_attributes.length}) do |x|
            x << link_to_if(column_dimension.has_children?, col_dim_value, table_view.column_link(col_dim_value))
          end
        end
      end

      x.tr do |x| # aggregated fact headers
        # Generate the row dimension's header
        x.th {|x| x << "#{row_dimension.hierarchy_level.to_s.humanize.titleize}"}
        table_view.data_columns.each do |column|
            x.th(column.label)
        end
      end

      table_view.data_rows.each do |data_row|
        x.tr do |x|
          x.td do |x| # row dimension label
            x << link_to_if(row_dimension.has_children?, data_row.dimension_value, table_view.row_link(data_row.dimension_value))
          end

          data_row.cells.each_with_index do |cell, index| # aggregated facts
            x.td do |x|
              x << link_to_if((report.link_cell && column_dimension.has_children? && row_dimension.has_children?), cell.value, 
                table_view.cell_link(cell.column_dimension_value,data_row.dimension_value)
              )
            end
          end
        end
      end
      
      if table_view.with_totals?
      # Add summary row at the bottom of the report
        x.tr({:class => 'total'}) do |x|
          x.td { |x| x << "Grand Totals"}
        
          table_view.data_columns.each_with_index do |column, index|
            x.td do |x|
              x << table_view.column_total(index)
            end
          end   
        end
      end
    end
  end

  def render_crumbs(crumbs)
    breadcrumb_html = []
    return if crumbs.size == 1
    
    crumbs.each do |crumb|
      if crumb != crumbs.last
        breadcrumb_html << link_to(crumb.link_to_name, crumb.link_to_params)
      else
        breadcrumb_html << crumb.link_to_name 
      end
    end
    result = breadcrumb_html.join(' &#187; ')
    result.blank? ? "" : "#{crumbs.last.crumb_type}: #{result}"
  end
  
  def render_chart_report(table_view, chart_id = "yui_chart")
    Yui4Rails::Widgets::Chart.new(:bar, chart_id, 
    {
      :data_rows => yui_data_rows(table_view), 
      :col_defs => yui_column_definitions(table_view), 
      :series_defs => yui_series_definitions(table_view),
      :y_field => "row_dimension_label"
    }).render
  end  
end