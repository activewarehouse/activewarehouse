require "#{File.dirname(__FILE__)}/test_helper"

class FactGeneratorTest < Test::Unit::TestCase
  def test_generator
    g = Rails::Generator::Base.instance('fact', %w(pos_sales_transaction), {:pretend => true})
    assert_equal 'pos_sales_transaction', g.name
    assert_equal 'pos_sales_transaction_facts', g.table_name
    assert_equal 'PosSalesTransactionFact', g.class_name
    assert_equal 'pos_sales_transaction_fact', g.file_name
  end
end