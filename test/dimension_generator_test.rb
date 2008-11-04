require "#{File.dirname(__FILE__)}/test_helper"

class DimensionGeneratorTest < Test::Unit::TestCase
  def test_generator
    g = Rails::Generator::Base.instance('dimension', %w(customer), {:pretend => true})
    assert_equal 'customer', g.name
    assert_equal 'customer_dimension', g.table_name
    assert_equal 'CustomerDimension', g.class_name
    assert_equal 'customer_dimension', g.file_name
  end
end