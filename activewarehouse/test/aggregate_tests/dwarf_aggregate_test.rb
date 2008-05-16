require "#{File.dirname(__FILE__)}/../test_helper"

class DwarfAggregateTest < Test::Unit::TestCase
  # def test_populate
#     assert_nothing_raised do
#       agg = ActiveWarehouse::Aggregate::DwarfAggregate.new(MultiDimensionalRegionalSalesCube)
#       agg.populate
#     end
#   end
#
#   def test_query
#     agg = ActiveWarehouse::Aggregate::DwarfAggregate.new(MultiDimensionalRegionalSalesCube)
#     agg.populate
#     results = agg.query(:date, :cy, :store, :region)
#   end
  
  def test_algorithm
    fact_table = [
      ['S1','C2','P2',70],
      ['S1','C3','P1',40],
      ['S2','C1','P1',90],
      ['S2','C1','P2',50],
    ]
    agg = ActiveWarehouse::Aggregate::DwarfAggregate.new(nil)
    agg.number_of_dimensions = 3
    agg.create_dwarf_cube(fact_table)
  end
  
end