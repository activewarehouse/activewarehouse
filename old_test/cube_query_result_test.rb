require File.join(File.dirname(__FILE__), 'test_helper')

class CubeQueryResultTest < Test::Unit::TestCase

  def setup
    super
    @cqr = ActiveWarehouse::CubeQueryResult.new(StoreInventorySnapshotFact.aggregate_fields)
  end
  
  def test_add_data
    @cqr.add_data('a', 'b', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
    assert_equal( {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2}, @cqr.values('a', 'b') )

    @cqr.add_data(2003, 'c', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
    assert_equal( {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2}, @cqr.values('2003', 'c') )
    
    assert_equal 1, @cqr.value('a', 'b', "Sum Quantity Sold")
    assert_equal 2, @cqr.value('a', 'b', "Sum Dollar Value At Cost")
    assert_equal 0, @cqr.value('b', 'b', "Sum Dollar Value At Cost")
  end
  
  def test_error_on_incorrect_agg_field_name
    assert_raise ArgumentError do
      @cqr.add_data('a', 'b', {"doesn't exist" => 1, "Sum Dollar Value At Cost" => 2})
    end
  end
  
  def test_error_on_empty_agg_fields
    assert_raise ArgumentError do
      @cqr = ActiveWarehouse::CubeQueryResult.new(nil)
    end
  end
  
  def test_has_row_values
    @cqr.add_data('a', 'b', {"Sum Quantity Sold" => 1, "Sum Dollar Value At Cost" => 2})
    assert @cqr.has_row_values?('a')
    assert ! @cqr.has_row_values?('b')
  end
  
end