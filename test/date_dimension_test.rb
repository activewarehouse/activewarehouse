require File.join(File.dirname(__FILE__), 'test_helper')

class DateDimensionTest < Test::Unit::TestCase

  def test_sql_date_stamp
    assert_equal 'sql_date_stamp', ActiveWarehouse::DateDimension.sql_date_stamp
    ActiveWarehouse::DateDimension.set_sql_date_stamp 'full_date'
    assert_equal 'full_date', ActiveWarehouse::DateDimension.sql_date_stamp
  end
  
end