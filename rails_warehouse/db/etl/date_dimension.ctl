# ETL Control file for date dimension

outfile = 'output/date_dimension.txt'
columns = [:date, :day_of_week, :day_number_in_calendar_month, :day_number_in_calendar_year,
  :calendar_week, :calendar_week_ending_date, :calendar_week_number_in_year, 
  :calendar_month_name, :calendar_month_number_in_year, :calendar_year_month, 
  :calendar_quarter, :calendar_year_quarter, :calendar_year, :major_event, :sql_date_stamp]

File.open("#{File.dirname(__FILE__)}/#{outfile}", 'w') do |out|
  start_date = Time.utc(2004, 11, 1)
  end_date = Time.utc(2007, 12, 31)
  date_builder = ETL::Builder::DateDimensionBuilder.new(start_date, end_date)
  date_builder.build.each_with_index do |row, index|
    column = [index+1]
    columns.each do |name|
      value = row[name]
      if value.is_a?(Time)
        column << value.to_s(:db)
      else
        column << value
      end
    end
    out.write(column.join(","))
    out.write("\n")
  end
end

post_process :bulk_import, {
  :file => outfile,
  :truncate => true,
  :columns => [:id, columns].flatten,
  :target => :warehouse,
  :table => 'date_dimension'
}