require "#{File.dirname(__FILE__)}/../test_helper"

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
    # 
    # puts  "\n\n\n\n********** test populate again **********\n\n\n\n"
    # assert RollupSalesTransactionsCube.populate
  end

end