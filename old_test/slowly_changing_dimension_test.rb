require "#{File.dirname(__FILE__)}/test_helper"

class SlowlyChangingDimensionTest < Test::Unit::TestCase
  # Test class methods
  def test_class_attributes
    assert_equal :latest_version, ProductDimension.latest_version_attribute
    assert_equal :effective_date, ProductDimension.effective_date_attribute
    assert_equal :expiration_date, ProductDimension.expiration_date_attribute
  end
  
  def test_find
    assert 7, ProductDimension.find(:all).length
    assert 7, ProductDimension.count
  end
  
  def test_find_with_valid_on
    desc = 'Crunchy Chips'
    crunchy_chips_1 = ProductDimension.find(1, :with_older => true)
    assert_equal '2006-01-01 00:00:00', crunchy_chips_1.effective_date.to_s(:db)
    
    crunchy_chips_2 = ProductDimension.find(8, :with_older => true)
    assert_equal '2006-12-01 00:00:00', crunchy_chips_2.effective_date.to_s(:db)
    
    assert_equal crunchy_chips_1, ProductDimension.find(:first, :conditions => ['product_description = ?', desc], :valid_on => '2006-02-01')
    assert_equal crunchy_chips_2, ProductDimension.find(:first, :conditions => ['product_description = ?', desc], :valid_on => Time.now)
  end
end