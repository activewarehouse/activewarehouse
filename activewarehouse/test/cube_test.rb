require "#{File.dirname(__FILE__)}/test_helper"

class CubeTest < Test::Unit::TestCase
  include StandardAggregationAssertions
  
  def test_dimensions
    assert_equal [:date, :store], RegionalSalesCube.dimensions
  end
  
  def test_class_name
    assert_equal "RegionalSalesCube", ActiveWarehouse::Cube.class_name(:regional_sales)
    assert_equal "RegionalSalesCube", ActiveWarehouse::Cube.class_name('regional_sales')
    assert_equal 'RegionalSalesCube', ActiveWarehouse::Cube.class_name(:regional_sales_cube)
    assert_equal 'RegionalSalesCube', ActiveWarehouse::Cube.class_name('regional_sales_cube')
  end
  
  def test_fact_class_name
    assert_equal "PosRetailSalesTransactionFact", RegionalSalesCube.fact_class_name
  end
  
  def test_fact_class
    assert_equal PosRetailSalesTransactionFact, RegionalSalesCube.fact_class
  end
  
  def test_dimension_classes
    assert_equal [DateDimension, StoreDimension], RegionalSalesCube.dimension_classes
  end
  
  def test_dimension_class
    assert_equal StoreDimension, RegionalSalesCube.dimension_class("store")  
  end
  
  def test_default_fact_is_assumed
    assert_equal "StoreInventorySnapshotFact", StoreInventorySnapshotCube.fact_class_name
  end
  
  def test_default_dimensions_assumed
    assert_equal [:date, :product, :store], StoreInventorySnapshotCube.dimensions.sort{|a,b| a.to_s <=> b.to_s}
  end
  
  def test_logger
    assert_not_nil RegionalSalesCube.logger
  end
  
  def test_last_modified
    last_modified = RegionalSalesCube.last_modified
    assert_not_nil last_modified
    assert_not_equal 0, last_modified
  end
  
  def test_populate
    assert_nothing_raised do
      RegionalSalesCube.populate
    end
  end
  
  def test_querying
    cube = RegionalSalesCube.new
    assert_query_success(cube)
    assert_old_style_query_success(cube)
    assert_query_drilldown_success(cube)
  end
  
  def test_set_aggregate_class
    RegionalSalesCube.aggregate_class(ActiveWarehouse::Aggregate::NoAggregate)
    assert RegionalSalesCube.aggregate.is_a?(ActiveWarehouse::Aggregate::NoAggregate)
  end
  
  def test_pivot_on_hierarchical_dimension
    assert !RegionalSalesCube.pivot_on_hierarchical_dimension?
    assert CustomerSalesCube.pivot_on_hierarchical_dimension?
  end
  
  def test_aggregate_fields
    assert_equal 8, CustomerSalesCube.aggregate_fields.length
    assert_equal 6, RegionalSalesCube.aggregate_fields.length    
    
    assert_equal 2, DailySalesCube.aggregate_fields.length    
    assert_equal 2, DailySalesCube.aggregate_fields([:date, :store]).length    
    assert_equal 1, DailySalesCube.aggregate_fields([:date, :product]).length
    assert_equal 2, DailySalesCube.aggregate_fields(['', 'store']).length        
  end
end