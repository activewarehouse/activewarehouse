module ActiveWarehouse #:nodoc:
  module Builder #:nodoc:
    # A builder which will build a data structure which can be used to populate a date dimension using 
    # commonly used date dimension columns.
    class DateDimensionBuilder
      # Specify the start date for the first record
      attr_accessor :start_date
      
      # Specify the end date for the last record
      attr_accessor :end_date
      
      # Define any holiday indicators
      attr_accessor :holiday_indicators
      
      # Define the weekday indicators. The default array begins on Sunday and goes to Saturday.
      cattr_accessor :weekday_indicators
      @@weekday_indicators = ['Weekend','Weekday','Weekday','Weekday','Weekday','Weekday','Weekend']
      
      # Initialize the builder.
      # 
      # * <tt>start_date</tt>: The start date. Defaults to 5 years ago from today.
      # * <tt>end_date</tt>: The end date. Defaults to now.
      def initialize(start_date=Time.now.years_ago(5), end_date=Time.now)
        @start_date = start_date
        @end_date = end_date
        @holiday_indicators = []
      end
      
      # Returns an array of hashes representing records in the dimension. The values for each record are 
      # accessed by name.
      def build(options={})
        records = []
        date = start_date.to_time
        while date <= end_date.to_time
          record = {}
          record[:date] = date.strftime("%m/%d/%Y")
          record[:full_date_description] = date.strftime("%B %d,%Y")
          record[:day_of_week] = date.strftime("%A")
          #record[:day_number_in_epoch] = date.to_i / 24
          #record[:week_number_in_epoch] = date.to_i / (24 * 7)
          #record[:month_number_in_epoch] = date.to_i / (24 * 7 * 30)
          record[:day_number_in_calendar_month] = date.day
          record[:day_number_in_calendar_year] = date.yday
          record[:day_number_in_fiscal_month] = date.day # should this be different from CY?
          record[:day_number_in_fiscal_year] = date.fiscal_year_yday
          #record[:last_day_in_week_indicator] = 
          #record[:last_day_in_month_indicator] =
          #record[:calendar_week_ending_date] = 
          record[:calendar_week] = "Week #{date.week}"
          record[:calendar_week_number] = date.week
          record[:calendar_week_number_in_year] = date.week
          record[:calendar_month_name] = date.strftime("%B")
          record[:calendar_month_number] = date.month
          record[:calendar_month_number_in_year] = date.month
          record[:calendar_year_month] = date.strftime("%Y-%m")
          record[:calendar_quarter] = "Q#{date.quarter}"
          record[:calendar_quarter_number] = date.quarter
          record[:calendar_quarter_number_in_year] = date.quarter
          record[:calendar_year_quarter] = "#{date.strftime('%Y')}-#{record[:calendar_quarter]}"
          #record[:calendar_half_year] = 
          record[:calendar_year] = "#{date.year}"
          record[:fiscal_week] = "FY Week #{date.fiscal_year_week}"
          record[:fiscal_week_number] = date.fiscal_year_week
          record[:fiscal_week_number_in_year] = date.fiscal_year_week
          record[:fiscal_month] = date.fiscal_year_month
          record[:fiscal_month_number] = date.fiscal_year_month
          record[:fiscal_month_number_in_year] = date.fiscal_year_month
          record[:fiscal_year_month] = "FY#{date.fiscal_year}-" + date.fiscal_year_month.to_s.rjust(2, '0')
          record[:fiscal_quarter] = "FY Q#{date.fiscal_year_quarter}"
          record[:fiscal_year_quarter] = "FY#{date.fiscal_year}-Q#{date.fiscal_year_quarter}"
          record[:fiscal_quarter_number] = date.fiscal_year_quarter
          record[:fiscal_year_quarter_number] = date.fiscal_year_quarter
          #record[:fiscal_half_year] = 
          record[:fiscal_year] = "FY#{date.fiscal_year}"
          record[:fiscal_year_number] = date.fiscal_year
          record[:holiday_indicator] = holiday_indicators.include?(date) ? 'Holiday' : 'Nonholiday'
          record[:weekday_indicator] = weekday_indicators[date.wday]
          record[:selling_season] = 'None'
          record[:major_event] = 'None'
          record[:sql_date_stamp] = date
          
          records << record
          date = date.tomorrow
        end
        records
      end
    end
  end
end
