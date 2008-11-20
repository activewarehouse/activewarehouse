require "#{File.dirname(__FILE__)}/test_helper"

class DimensionViewGeneratorTest < Test::Unit::TestCase
  def test_generator
    g = Rails::Generator::Base.instance('dimension_view', %w(order_date date), {:pretend => true})
    assert_equal 'order_date', g.name
    assert_equal 'order_date_dimension', g.view_name
    assert_equal DateDimension.column_names, g.view_attributes
    #assert_equal 'select id,calendar_month_number_in_year,day_number_in_epoch,fiscal_week,calendar_half_year,day_number_in_fiscal_month,calendar_year_month,week_number_in_epoch,fiscal_half_year,fiscal_year_quarter,fiscal_week_number_in_year,day_number_in_fiscal_year,sql_date_stamp,holiday_indicator,calendar_quarter,month_number_in_epoch,full_date_description,fiscal_year,calendar_week,weekday_indicator,last_day_in_week_indicator,day_of_week,calendar_week_number_in_year,selling_season,calendar_year_quarter,last_day_in_month_indicator,day_number_in_calendar_month,fiscal_quarter,calendar_month_name,major_event,fiscal_year_month,calendar_year,calendar_week_ending_date,day_number_in_calendar_year,date from date_dimension', g.view_query
  end
end