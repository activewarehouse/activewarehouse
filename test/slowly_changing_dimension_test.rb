require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper'))

class SlowlyChangingDimensionTest < Test::Unit::TestCase
  # Test class methods
  def test_class_attributes
    assert_equal :latest_version, ProductDimension.latest_version_attribute
    assert_equal :effective_date, ProductDimension.effective_date_attribute
    assert_equal :expiration_date, ProductDimension.expiration_date_attribute
  end
  
  def test_find
    assert_equal 7, ProductDimension.find(:all).length
    assert_equal 7, ProductDimension.count
  end
  
  def test_find_with_valid_on
    desc = 'Crunchy Chips'
    crunchy_chips = ProductDimension.find_with_older(1)
    assert_equal 1, crunchy_chips.size
    crunchy_chips_1 = crunchy_chips.first
    assert_equal '2006-01-01 00:00:00', crunchy_chips_1.effective_date.to_s(:db)
    
    crunchy_chips = ProductDimension.find_with_older(8)
    assert_equal 1, crunchy_chips.size
    crunchy_chips_2 = crunchy_chips.first
    assert_equal '2006-12-01 00:00:00', crunchy_chips_2.effective_date.to_s(:db)
    
    assert_equal crunchy_chips_1, ProductDimension.unscoped { ProductDimension.valid_on(Date.parse('2006-02-01')).where('product_description = ?', desc).first }
    assert_equal crunchy_chips_2, ProductDimension.unscoped { ProductDimension.valid_on(Time.now).where('product_description = ?', desc).first }

  end
end
