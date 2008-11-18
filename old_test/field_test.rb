require File.join(File.dirname(__FILE__), 'test_helper')

class FieldTest < Test::Unit::TestCase

  def setup
    super
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"])
  end
  
  def test_name
    assert_equal "quantity_sold", @field.name
  end
  
  def test_column_type
    assert_equal :integer, @field.column_type
  end
  
  def test_scale
    assert_equal nil, @field.scale
  end
  
  def test_precision
    assert_equal nil, @field.precision
  end
  
  def test_scale_and_precision_with_decimal
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["dollar_value_at_latest_selling_price"])
    assert_equal 18, @field.precision
    assert_equal 2, @field.scale
  end
  
  def test_from_table_name
    assert_equal "store_inventory_snapshot_facts", @field.from_table_name
  end
  
  def test_owning_class
    assert_equal StoreInventorySnapshotFact, @field.owning_class
  end
  
  def test_type_cast
    expected_value = StoreInventorySnapshotFact.columns_hash["quantity_sold"].type_cast('1')
    assert_equal expected_value, @field.type_cast('1')
  end
  
  def test_field_options
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :label => 'My Field')
    assert_equal({:label=> 'My Field'}, @field.field_options)
    assert_equal 'My Field', @field.label
  end
  
  def test_default_label
    assert_equal "store_inventory_snapshot_facts_quantity_sold_sum", @field.label
  end
  
  def test_label_for_table
    @field = ActiveWarehouse::AggregateField.new(StoreInventorySnapshotFact,
        StoreInventorySnapshotFact.columns_hash["quantity_sold"], :sum, :label => "My Sum")
    assert "my_sum", @field.label_for_table
  end
end