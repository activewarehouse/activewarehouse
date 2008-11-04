require File.join(File.dirname(__FILE__), 'test_helper')

class BridgeTest < Test::Unit::TestCase

  def test_table_name
    assert_equal 'customer_hierarchy_bridge', CustomerHierarchyBridge.table_name
  end
end