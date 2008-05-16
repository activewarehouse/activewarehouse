require File.dirname(__FILE__) + '/test_helper'

class DateDimensionBuilderTest < Test::Unit::TestCase
  
  def test_initialization_defaults
    start_date = Time.now.years_ago(5)
    end_date = Time.now
    builder = ETL::Builder::DateDimensionBuilder.new
    assert_time_equal start_date, builder.start_date
    assert_time_equal end_date, builder.end_date
    assert_equal [], builder.holiday_indicators
  end
  
  def test_initializations_with_preset_values    
    start_date = Time.now.years_ago(2)
    end_date = Time.now.years_ago(1)
    builder = ETL::Builder::DateDimensionBuilder.new(start_date, end_date)
    assert_time_equal start_date, builder.start_date
    assert_time_equal end_date, builder.end_date
  end
  
  def test_build
    builder = ETL::Builder::DateDimensionBuilder.new
    records = builder.build
    assert_equal 1827, records.length
    assert_date_dimension_record_equal(builder.start_date, records.first)
  end
  
  def assert_time_equal(t1, t2)
    assert_equal t1.year, t2.year
    assert_equal t1.month, t2.month
    assert_equal t1.hour, t2.hour
    assert_equal t1.min, t2.min
  end
  
  def assert_date_dimension_record_equal(date, record)
    assert_equal date.strftime("%m/%d/%Y"), record[:date]
    assert_equal date.strftime("%B %d,%Y"), record[:full_date_description]
    assert_equal date.strftime("%A"), record[:day_of_week]
    assert_equal date.day, record[:day_number_in_calendar_month]
    assert_equal date.yday, record[:day_number_in_calendar_year]
    assert_equal date.day, record[:day_number_in_fiscal_month]
    assert_equal date.fiscal_year_yday, record[:day_number_in_fiscal_year]
    assert_equal "Week #{date.week}", record[:calendar_week]
    assert_equal date.week, record[:calendar_week_number_in_year]
    assert_equal date.strftime("%B"), record[:calendar_month_name]
    assert_equal date.month, record[:calendar_month_number_in_year]
    assert_equal date.strftime("%Y-%m"), record[:calendar_year_month]
    assert_equal "Q#{date.quarter}", record[:calendar_quarter]
    assert_equal date.quarter, record[:calendar_quarter_number_in_year]
    assert_equal "#{date.strftime('%Y')}-#{record[:calendar_quarter]}", record[:calendar_year_quarter]
    assert_equal "#{date.year}", record[:calendar_year]
    assert_equal "FY Week #{date.fiscal_year_week}", record[:fiscal_week]
    assert_equal date.fiscal_year_week, record[:fiscal_week_number_in_year]
    assert_equal date.fiscal_year_month, record[:fiscal_month]
    assert_equal date.fiscal_year_month, record[:fiscal_month_number_in_year]
    assert_equal "FY#{date.fiscal_year}-" + date.fiscal_year_month.to_s.rjust(2, '0'), record[:fiscal_year_month]
    assert_equal "FY Q#{date.fiscal_year_quarter}", record[:fiscal_quarter]
    assert_equal "FY#{date.fiscal_year}-Q#{date.fiscal_year_quarter}", record[:fiscal_year_quarter]
    assert_equal date.fiscal_year_quarter, record[:fiscal_year_quarter_number]
    assert_equal "FY#{date.fiscal_year}", record[:fiscal_year]
    assert_equal date.fiscal_year, record[:fiscal_year_number]
    assert_equal 'Nonholiday', record[:holiday_indicator]
    assert_equal weekday_indicators[date.wday], record[:weekday_indicator]
    assert_equal 'None', record[:selling_season]
    assert_equal 'None', record[:major_event]
    assert_equal record[:sql_date_stamp], date
  end
  
  private
  def weekday_indicators
    ['Weekend','Weekday','Weekday','Weekday','Weekday','Weekday','Weekend']
  end
end