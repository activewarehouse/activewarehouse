require "#{File.dirname(__FILE__)}/test_helper"

class HierarchicalDimensionTest < Test::Unit::TestCase
  # Test class methods
  def test_bridge_class
    bridge_class = CustomerDimension.bridge_class
    
    assert_equal 'CustomerHierarchyBridge', CustomerDimension.bridge_class_name
    assert_equal CustomerHierarchyBridge, bridge_class
    assert_equal 'customer_hierarchy_bridge', bridge_class.table_name
  end
  
  # Instance methods
  def test_parent
    customer1 = CustomerDimension.find(1)
    assert_nil customer1.parent
    
    customer2 = CustomerDimension.find(2)
    assert_not_nil customer2.parent
    assert_equal customer1, customer2.parent    
  end
  
  def test_children
    customer1 = CustomerDimension.find(1)
    customer2 = CustomerDimension.find(2)
    customer7 = CustomerDimension.find(7)
    assert_not_nil customer1.children
    assert_equal [customer2, customer7], customer1.children
  end
end