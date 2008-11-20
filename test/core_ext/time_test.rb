require File.join(File.dirname(__FILE__), '../test_helper')

class TimeTest < Test::Unit::TestCase
  def test_calendar_year_week
    t = Time.parse('2005-01-01')
    assert_equal 1, t.week
    t = Time.parse('2005-12-30')
    assert_equal 52, t.week
  end
  def test_calendar_year_quarter
    t = Time.parse('2005-01-01')
    assert_equal 1, t.quarter
    t = Time.parse('2005-12-30')
    assert_equal 4, t.quarter
  end
  def test_fiscal_year_week
    t = Time.parse('2005-10-01')
    assert_equal 1, t.fiscal_year_week
    t = Time.parse('2005-11-01')
    assert_equal 5, t.fiscal_year_week
  end
  def test_fiscal_year_week_with_non_default_offset
    t = Time.parse('2006-07-01')
    assert_equal 1, t.fiscal_year_week(7)
  end
  def test_fiscal_year_month
    t = Time.parse('2006-10-10')
    assert_equal 1, t.fiscal_year_month
    t = Time.parse('2006-11-01')
    assert_equal 2, t.fiscal_year_month
  end
  def test_fiscal_year_month_with_non_default_offset
    t = Time.parse('2006-07-10')
    assert_equal 1, t.fiscal_year_month(7)
  end
  def test_fiscal_year_quarter
    t = Time.parse('2005-10-01')
    assert_equal 1, t.fiscal_year_quarter
    t = Time.parse('2005-12-31')
    assert_equal 1, t.fiscal_year_quarter
    t = Time.parse('2006-01-01')
    assert_equal 2, t.fiscal_year_quarter
    t = Time.parse('2006-04-01')
    assert_equal 3, t.fiscal_year_quarter
  end
  def test_fiscal_year_quarter_with_non_default_offset
    t = Time.parse('2006-07-01')
    assert_equal 1, t.fiscal_year_quarter(7)
  end
  def test_fiscal_year
    t = Time.parse('2005-10-01')
    assert_equal 2006, t.fiscal_year
    t = Time.parse('2005-12-31')
    assert_equal 2006, t.fiscal_year
    t = Time.parse('2006-01-01')
    assert_equal 2006, t.fiscal_year
    t = Time.parse('2006-10-10')
    assert_equal 2007, t.fiscal_year
  end
  def test_fiscal_year_with_non_default_offset
    t = Time.parse('2005-07-01')
    assert_equal 2006, t.fiscal_year(7)
  end
  def test_fiscal_year_yday
    t = Time.parse('2005-10-01')
    assert_equal 1, t.fiscal_year_yday
    t = Time.parse('2006-09-30')
    assert_equal 365, t.fiscal_year_yday
  end
end