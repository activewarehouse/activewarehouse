require File.join(File.dirname(__FILE__), 'test_helper')

class HierarchyBridgeTest < Test::Unit::TestCase
  def test_effective_date
    assert_equal 'effective_date', ActiveWarehouse::HierarchyBridge.effective_date
    ActiveWarehouse::HierarchyBridge.set_effective_date 'start_date'
    assert_equal 'start_date', ActiveWarehouse::HierarchyBridge.effective_date
  end
  
  def test_expiration_date
    assert_equal 'expiration_date', ActiveWarehouse::HierarchyBridge.expiration_date
    ActiveWarehouse::HierarchyBridge.set_expiration_date 'end_date'
    assert_equal 'end_date', ActiveWarehouse::HierarchyBridge.expiration_date
  end
  
  def test_levels_from_parent
    assert_equal 'levels_from_parent', ActiveWarehouse::HierarchyBridge.levels_from_parent
    ActiveWarehouse::HierarchyBridge.set_levels_from_parent 'num_levels'
    assert_equal 'num_levels', ActiveWarehouse::HierarchyBridge.levels_from_parent
  end
  
  def test_top_flag
    assert_equal 'top_flag', ActiveWarehouse::HierarchyBridge.top_flag
    ActiveWarehouse::HierarchyBridge.set_top_flag 'top_level'
    assert_equal 'top_level', ActiveWarehouse::HierarchyBridge.top_flag
  end
  
  def test_top_flag_value
    assert_equal 'Y', ActiveWarehouse::HierarchyBridge.top_flag_value
    ActiveWarehouse::HierarchyBridge.set_top_flag_value 'Yes'
    assert_equal 'Yes', ActiveWarehouse::HierarchyBridge.top_flag_value
  end
end