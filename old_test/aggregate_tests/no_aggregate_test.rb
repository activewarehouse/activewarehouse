require "#{File.dirname(__FILE__)}/../test_helper"

class NoAggregateTest < Test::Unit::TestCase
  include StandardAggregationAssertions
  include HierarchicalDimensionAggregationAssertions
  include HierarchicalSlowlyChangingDimensionAggregationAssertions
  
  def test_query
    agg = ActiveWarehouse::Aggregate::NoAggregate.new(RegionalSalesCube)
    assert_query_success(agg)
    assert_old_style_query_success(agg)
    assert_query_drilldown_success(agg)
  end
  
  def test_hierarchy_query
    agg = ActiveWarehouse::Aggregate::NoAggregate.new(CustomerSalesCube)
    assert_hierarchical_query_success(agg)
    assert_hierarchical_query_drilldown_success(agg)
  end
  
  def test_hieararchy_scd_query
    agg = ActiveWarehouse::Aggregate::NoAggregate.new(SalespersonSalesCube)
    assert_hierarchical_scd_query_success(agg)
    assert_scd_without_date(agg)
  end
  
  def test_has_and_belongs_to_many_query
    agg = ActiveWarehouse::Aggregate::NoAggregate.new(DailySalesCube)
    assert_count_distinct_success(agg)
  end
end