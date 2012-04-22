require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class CalculatedFieldTest < Test::Unit::TestCase

  def setup
    super
    @field = ActiveWarehouse::CalculatedField.new(
      StoreInventorySnapshotFact, :average_quantity_sold
    ) { |r| r[:x] * 10 }
  end

  def test_owning_class
    assert_equal StoreInventorySnapshotFact, @field.owning_class
  end

  def test_default_label
    assert_equal "store_inventory_snapshot_facts_average_quantity_sold", @field.label
  end

  def test_label
    @field = ActiveWarehouse::CalculatedField.new(StoreInventorySnapshotFact,
                                                  :average_quantity_sold, :float, :label => "My Sum") { |r| r[:x] }
    assert_equal "My Sum", @field.label
  end

  def test_label_for_table
    @field = ActiveWarehouse::CalculatedField.new(StoreInventorySnapshotFact,
                                                  :average_quantity_sold, :float, :label => "My Sum") { |r| r[:x] }
    assert_equal "my_sum", @field.label_for_table
  end

  def test_calculate
    assert_equal 20, @field.calculate(:x => 2)
  end

  def test_raise_argument_error
    assert_raises ArgumentError do
      ActiveWarehouse::CalculatedField.new(StoreInventorySnapshotFact, :foo)
    end
  end

end
