require File.join(File.dirname(__FILE__), 'test_helper')

class DimensionBuilderTest < Test::Unit::TestCase
  def test_build
    start_time = Time.parse('2002-01-01')
    start_date = start_time.to_date
    end_date = start_time.years_since(5).yesterday.to_date
    ddb = ActiveWarehouse::Builder::DateDimensionBuilder.new(start_date, end_date)
    ddb.holiday_indicators << start_date
    records = ddb.build
    assert_equal 1826, records.length
    
    record = records.first
    assert_equal '01/01/2002', record[:date]
    assert_equal 'January 01,2002', record[:full_date_description]
    assert_equal 'Tuesday', record[:day_of_week]
    assert_equal 1, record[:day_number_in_calendar_month]
    assert_equal 1, record[:day_number_in_calendar_year]
    assert_equal 1, record[:day_number_in_fiscal_month]
    assert_equal 93, record[:day_number_in_fiscal_year]
    assert_equal 'Week 1', record[:calendar_week]
    assert_equal 1, record[:calendar_week_number_in_year]
    assert_equal 'January', record[:calendar_month_name]
    assert_equal 1, record[:calendar_month_number_in_year]
    assert_equal '2002-01', record[:calendar_year_month]
    assert_equal 'Q1', record[:calendar_quarter]
    assert_equal '2002-Q1', record[:calendar_year_quarter]
    assert_equal '2002', record[:calendar_year]
    assert_equal 'FY Week 14', record[:fiscal_week]
    assert_equal 14, record[:fiscal_week_number_in_year]
    assert_equal 4, record[:fiscal_month]
    assert_equal 4, record[:fiscal_month_number_in_year]
    assert_equal "FY2002-04", record[:fiscal_year_month]
    assert_equal "FY Q2", record[:fiscal_quarter]
    assert_equal "FY2002-Q2", record[:fiscal_year_quarter]
    assert_equal "FY2002", record[:fiscal_year]
    assert_equal "Holiday", record[:holiday_indicator]
    assert_equal 'Weekday', record[:weekday_indicator]
    assert_equal 'None', record[:selling_season]
    assert_equal 'None', record[:major_event]
    assert_equal start_date, record[:sql_date_stamp]
    
    record = records.last
    assert_equal '12/31/2006', record[:date]
    assert_equal 'Sunday', record[:day_of_week]
    assert_equal 31, record[:day_number_in_calendar_month]
    assert_equal 365, record[:day_number_in_calendar_year]
    assert_equal 31, record[:day_number_in_fiscal_month]
    assert_equal 92, record[:day_number_in_fiscal_year]
    assert_equal 'Week 52', record[:calendar_week]
    assert_equal 52, record[:calendar_week_number_in_year]
    assert_equal 'December', record[:calendar_month_name]
    assert_equal 12, record[:calendar_month_number_in_year]
    assert_equal '2006-12', record[:calendar_year_month]
    assert_equal 'Q4', record[:calendar_quarter]
    assert_equal '2006-Q4', record[:calendar_year_quarter]
    assert_equal '2006', record[:calendar_year]
    assert_equal 'FY Week 14', record[:fiscal_week]
    assert_equal 14, record[:fiscal_week_number_in_year]
    assert_equal 3, record[:fiscal_month]
    assert_equal 3, record[:fiscal_month_number_in_year]
    assert_equal "FY2007-03", record[:fiscal_year_month]
    assert_equal "FY Q1", record[:fiscal_quarter]
    assert_equal "FY2007-Q1", record[:fiscal_year_quarter]
    assert_equal "FY2007", record[:fiscal_year]
    assert_equal "Nonholiday", record[:holiday_indicator]
    assert_equal 'Weekend', record[:weekday_indicator]
    assert_equal 'None', record[:selling_season]
    assert_equal 'None', record[:major_event]
    assert_equal end_date, record[:sql_date_stamp]
  end
  
  def test_fiscal_year_week
    start_date = Time.parse('2001-10-01')
    end_date = start_date.years_since(1)
    ddb = ActiveWarehouse::Builder::DateDimensionBuilder.new(start_date, end_date)
    records = ddb.build
    
    assert_equal 'FY Week 1', records.first[:fiscal_week]
  end
end


