require "#{File.dirname(__FILE__)}/test_helper"

class DimensionTest < Test::Unit::TestCase
  # Test class methods
  def test_hierarchy
    cy_hierarchy = DateDimension.hierarchy(:cy)
    assert_not_nil cy_hierarchy
    assert_equal 5, cy_hierarchy.length
    assert_equal :calendar_year, cy_hierarchy[0]
    
    fy_hierarchy = DateDimension.hierarchy(:fy)
    assert_not_nil fy_hierarchy
    assert_equal 5, fy_hierarchy.length
    assert_equal :fiscal_year, fy_hierarchy[0]
  end
  def test_hierarchies
    assert_equal 2, DateDimension.hierarchies.length
    assert_equal 2, StoreDimension.hierarchies.length
  end
  def test_table_name
    assert_equal 'date_dimension', DateDimension.table_name
  end
  def test_class_name
    assert_equal 'DateDimension', DateDimension.class_name(:date)
    assert_equal 'DateDimension', DateDimension.class_name('date')
    assert_equal 'DateDimension', DateDimension.class_name(:date_dimension)
    assert_equal 'DateDimension', DateDimension.class_name('date_dimension')
    assert_equal 'DateDimension', ActiveWarehouse::Dimension.class_name(:date)
    assert_equal 'DateDimension', ActiveWarehouse::Dimension.class_name('date')
    assert_equal 'DateDimension', ActiveWarehouse::Dimension.class_name(:date_dimension)
    assert_equal 'DateDimension', ActiveWarehouse::Dimension.class_name('date_dimension')
  end
  def test_class_for_name
    assert_equal DateDimension, DateDimension.class_for_name(:date)
    assert_equal DateDimension, DateDimension.class_for_name('date')
    assert_equal DateDimension, DateDimension.class_for_name(:date_dimension)
    assert_equal DateDimension, DateDimension.class_for_name('date_dimension')
    assert_equal DateDimension, ActiveWarehouse::Dimension.class_for_name(:date)
    assert_equal DateDimension, ActiveWarehouse::Dimension.class_for_name('date')
    assert_equal DateDimension, ActiveWarehouse::Dimension.class_for_name(:date_dimension)
    assert_equal DateDimension, ActiveWarehouse::Dimension.class_for_name('date_dimension')
  end
  def test_last_modified
    assert_not_nil DateDimension.last_modified
  end
  def test_to_dimension
    assert_equal DateDimension, DateDimension.to_dimension(:date)
    assert_equal DateDimension, DateDimension.to_dimension(DateDimension)
    assert_equal DateDimension, ActiveWarehouse::Dimension.to_dimension(:date)
    assert_equal DateDimension, ActiveWarehouse::Dimension.to_dimension(DateDimension)
  end
  def test_foreign_key
    assert_equal 'date_id', DateDimension.foreign_key
  end
  
  def test_available_values
    values = DateDimension.available_values(:calendar_year)
    
    assert_not_nil values
    assert_equal 8, values.length
    assert_equal '2001', values.first
    assert_equal '2008', values.last
    
    month_names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 
    'October', 'November', 'December']
    
    assert_equal month_names, DateDimension.available_values(:calendar_month_name)
    
    assert_equal ["Northeast","Southeast"], StoreDimension.available_values(:store_region)
    assert_equal ["New York", "South Florida"], StoreDimension.available_values(:store_district)
  end
  def test_available_child_values
    assert_equal ["2001", "2002", "2003", "2004", "2005", "2006", "2007", "2008"], DateDimension.available_child_values(:cy, [])
    assert_equal ['Q1', 'Q2', 'Q3', 'Q4'], DateDimension.available_child_values(:cy, [2006])
    assert_equal ['January', 'February', 'March'], DateDimension.available_child_values(:cy, [2006, 'Q1'])
  end
  def test_available_values_tree
    root = StoreDimension.available_values_tree(:location)
    #pp root
    assert_equal 'All', root.value
    assert root.has_child?('New York'), 'Root node does not have child New York'
    assert_equal ['Florida','New York'], root.children.collect { |node| node.value }
    
    assert_nothing_raised do
      florida = StoreDimension.find(:first, :conditions => ['store_state = ?', 'Florida'])
      florida.store_state = 'Florida!'
      florida.save!
    end
  end
  def test_denominator_count
    assert_equal 4, DateDimension.denominator_count(:cy, :calendar_year, :calendar_quarter)["2002"]
    assert_equal 12, DateDimension.denominator_count(:cy, :calendar_year, :calendar_month_name)["2002"]
    assert_equal 52, DateDimension.denominator_count(:cy, :calendar_year, :calendar_week)["2002"]
    assert_equal 365, DateDimension.denominator_count(:cy, :calendar_year, :day_of_week)["2002"]
    assert_equal 365, DateDimension.denominator_count(:cy, :calendar_year)["2002"]
    
    assert_equal 366, DateDimension.denominator_count(:cy, :calendar_year)["2004"]
    
    assert_equal 3, DateDimension.denominator_count(:cy, :calendar_quarter, :calendar_month_name)["Q1"]
    
    assert_equal 12, DateDimension.denominator_count(:fy, :fiscal_year, :calendar_month_name)["FY2003"]
    
    assert_raises(ArgumentError, "The denominator level 'bogus_name' does not appear to exist") do
      DateDimension.denominator_count(:cy, :calendar_year, :bogus_name)
    end
    assert_raises(ArgumentError, "The hierarchy 'bogus_name' does not appear to exist in your dimension DateDimension") do 
      DateDimension.denominator_count(:bogus_name, :calendar_year)
    end
    assert_raises(ArgumentError, "The index of the denominator level 'calendar_year' in the hierarchy 'cy' must be greater than or equal to the level 'calender_month_name'") do
      DateDimension.denominator_count(:cy, :calendar_month_name, :calendar_year)
    end
  end
end
