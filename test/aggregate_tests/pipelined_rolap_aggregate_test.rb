require File.expand_path(File.join(File.dirname(__FILE__), '../test_helper'))

class PipelinedRolapAggregateTest < Test::Unit::TestCase

  def setup
    @aggregate = RollupSalesTransactionsCube.aggregate
  end

  def test_initialize
    agg = RollupSalesTransactionsCube.aggregate
    assert agg
  end
  
  # common methods
  def test_aggregate_dimension_fields
    puts "test_aggregate_dimension_fields start"
    cols = @aggregate.aggregate_dimension_fields
    cols.each{|d,cols| cols.each{|c| puts "#{d.name} #{c.name} #{c.type}"}}
  end
  
  def test_aggregated_fact_column_sql
    sql = @aggregate.aggregated_fact_column_sql
    puts sql
    assert sql
  end
  
  def test_tables_and_joins
    sql = @aggregate.tables_and_joins
    puts sql
    assert sql
  end
  
  def test_populate
    puts  "test populate"
    assert RollupSalesTransactionsCube.populate
  end
  
  def test_query

    filters = {
      'date.calendar_year' => '2001',
      'store.store_region'=>'Northeast'
    }

    cube = RollupSalesTransactionsCube.new
    results = cube.query(
      :column => :date, 
      :row => :product,
      :cstage => 3, 
      :rstage => 0,
      :filters => filters,
      :conditions => nil
    )
    
    puts results.inspect
    
  end

  def test_query_super

    filters = {
      'date.calendar_year' => '2001'
    }

    cube = RollupSalesTransactionsCube.new
    results = cube.query(
      :column_dimension_name => :date,
      :column_hierarchy_name => :cy,
      :row_dimension_name => :product,
      :row_hierarchy_name => :brand,
      :cstage => 3, 
      :rstage => 0,
      :filters => filters,
      :conditions => nil
    )
    
    puts results.inspect
    
  end

end
