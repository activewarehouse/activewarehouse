require File.join(File.dirname(__FILE__), 'test_helper')

class Smoochy
end
class RandomDataBuilderTest < Test::Unit::TestCase
  attr_accessor :builder
  
  def setup
    @builder = ActiveWarehouse::Builder::RandomDataBuilder.new
  end
  
  def test_build_with_dimension
    rows = builder.build(CustomerDimension)
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['customer_name'].length }
    
    rows = builder.build(:customer_dimension)
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['customer_name'].length }
    
    rows = builder.build('customer_dimension')
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['customer_name'].length }
  end
  
  def test_build_with_fact
    rows = builder.build(PosRetailSalesTransactionFact)
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['pos_transaction_number'].length }
    
    rows = builder.build(:pos_retail_sales_transaction_fact)
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['pos_transaction_number'].length }
    
    rows = builder.build('pos_retail_sales_transaction_fact')
    assert_equal 100, rows.length
    rows.each { |row| assert_equal 255, row['pos_transaction_number'].length }
  end
  
  def test_build_with_invalid_name
    assert_raise(RuntimeError, "Cannot find a class named Foo") do
      builder.build('foo')
    end
    assert_raise(RuntimeError, "Cannot find a class named Foo") do
      builder.build(:foo)
    end
    assert_raise(RuntimeError, "Smoochy is a class but does not appear to descend from Fact or Dimension") do
      builder.build(Smoochy)
    end
  end
  
  def test_build_dimension
    rows = builder.build_dimension(:customer)
    assert_equal 100, rows.length
    rows.each do |row|
      assert_equal 255, row['customer_name'].length
    end
  end
  
  def test_build_dimension_with_options
    rows = builder.build_dimension(:customer, :rows => 1000)
    assert_equal 1000, rows.length
    assert_equal 255, rows.first['customer_name'].length
  end
  
  def test_build_fact
    rows = builder.build_fact(:pos_retail_sales_transaction)
    assert_equal 100, rows.length
    rows.each do |row|
      assert row['date_id'] > 0 && row['date_id'] <= 100, 
        "Date Id should be > 0 and <= 100, but was #{row['date_id']}"
      assert_equal 255, row['pos_transaction_number'].length
      assert_equal Float, row['sales_dollar_amount'].class
      assert row['sales_dollar_amount'] > 0 && row['sales_dollar_amount'] <= 1000, 
        "Sales dollar amount should be > 0 and <= 1000, but was #{row['sales_dollar_amount']}"
    end
  end
  
  class SpecialStringGenerator < ActiveWarehouse::Builder::AbstractGenerator
    attr_reader :values
    def initialize
      @values = ['Bob','Joe','Jim']
    end
    def generate(column, options={})
      values[rand(values.length)]
    end
  end
  
  def test_custom_column_generator
    g = SpecialStringGenerator.new
    builder.column_generators['customer_name'] = g
    rows = builder.build_dimension(CustomerDimension)
    assert_equal 100, rows.length
    rows.each do |row|
      assert g.values.include?(row['customer_name']), "Expected one of #{g.values.inspect} but was #{row['customer_name']}"
    end
  end
  
  def test_date_generator
    start_date = 1.year.ago
    end_date = Time.now
    g = ActiveWarehouse::Builder::DateGenerator.new
    column = DateDimension.columns_hash['sql_time_stamp']
    assert_nothing_raised do
      1000.times do
        value = g.generate(column)
        assert_not_nil value
        assert_equal Date, value.class
        assert value.year >= start_date.year, "#{value.year} should be >= #{start_date.year}"
        assert value.year <= end_date.year, "#{value.year} should be < #{end_date.year}"
      end
    end
  end
  
  def test_date_generator_with_start_date_option
    start_date = 5.years.ago
    end_date = Time.now
    g = ActiveWarehouse::Builder::DateGenerator.new
    column = DateDimension.columns_hash['sql_time_stamp']
    assert_nothing_raised do
      1000.times do
        value = g.generate(column, :start_date => start_date)
        assert_not_nil value
        assert_equal Date, value.class
        assert value.year >= start_date.year, "#{value.year} should be >= #{start_date.year}"
        assert value.year <= end_date.year, "#{value.year} should be < #{end_date.year}"
      end
    end
  end
  
  def test_date_generator_with_end_date_option
    start_date = 1.year.ago
    end_date = 5.years.from_now
    g = ActiveWarehouse::Builder::DateGenerator.new
    column = DateDimension.columns_hash['sql_time_stamp']
    assert_nothing_raised do
      1000.times do
        value = g.generate(column, :start_date => start_date, :end_date => end_date)
        assert_not_nil value
        assert_equal Date, value.class
        assert value.year >= start_date.year, "#{value.year} should be >= #{start_date.year}"
        assert value.year <= end_date.year, "#{value.year} should be < #{end_date.year}"
      end
    end  
  end
  
  def test_time_generator
    start_date = 1.year.ago
    end_date = Time.now
    g = ActiveWarehouse::Builder::TimeGenerator.new
    column = DateDimension.columns_hash['sql_time_stamp']
    assert_nothing_raised do
      1000.times do
        value = g.generate(column)
        assert_not_nil value
        assert_equal Time, value.class
        assert value.year >= start_date.year, "#{value.year} should be >= #{start_date.year}"
        assert value.year <= end_date.year, "#{value.year} should be < #{end_date.year}"
      end
    end
  end
  
  def test_fixnum_generator
    g = ActiveWarehouse::Builder::FixnumGenerator.new
    column = DateDimension.columns_hash['month_number_in_epoch']
    assert_not_nil column
    assert Fixnum, g.generate(column).class
    1000.times do
      value = g.generate(column)
      assert value >= 0
      assert value < 1000
    end
  end
  
  def test_float_generator
    g = ActiveWarehouse::Builder::FloatGenerator.new
    column = PosRetailSalesTransactionFact.columns_hash['sales_dollar_amount']
    assert_not_nil column
    value = g.generate(column)
    assert Float, value.class
  end
  
  def test_big_decimal_generator
    g = ActiveWarehouse::Builder::BigDecimalGenerator.new
    column = PosRetailSalesTransactionFact.columns_hash['sales_dollar_amount']
    value = g.generate(column)
    assert BigDecimal, value.class
  end
  
  def test_string_generator
    g = ActiveWarehouse::Builder::StringGenerator.new
    column = CustomerDimension.columns_hash['customer_name']
    assert_not_nil column
    assert_equal 255, g.generate(column).length
  end
  
  def test_boolean_generator
    g = ActiveWarehouse::Builder::BooleanGenerator.new
    value = g.generate(nil)
    assert value.class == (FalseClass || TrueClass)
  end
end