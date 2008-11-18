require File.join(File.dirname(__FILE__), 'test_helper')

class AggregateFieldTest < Test::Unit::TestCase

  def setup
    super
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"])
  end
  
  def test_fact_class
    assert StoreInventorySnapshotFact, @field.fact_class
  end
  
  def test_semiadditive
    assert ! @field.is_semiadditive?
    
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :semiadditive => :date)
        
    assert @field.is_semiadditive?
  end
  
  def test_semiadditive_over
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :semiadditive => :date)
    assert DateDimension, @field.semiadditive_over
  end
  
  def test_default_strategy_name
    assert :sum, @field.strategy_name
  end
  
  def test_strategy_name_specified
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :count)
    assert :count, @field.strategy_name
  end
  
  def test_default_label
    assert "store_inventory_snapshot_facts_quantity_sold_sum", @field.label
  end
  
  def test_label
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :label => "My Sum")
    assert "My Sum", @field.label
  end
  
  def test_label_for_table
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :label => "My Sum")
    assert "my_sum", @field.label_for_table
  end
  
end