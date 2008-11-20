require "#{File.dirname(__FILE__)}/test_helper"

class FactTest < Test::Unit::TestCase
  
  def test_dimensions
    assert_equal [:customer, :date, :product, :promotion, :store], PosRetailSalesTransactionFact.dimensions.sort { |a, b| a.to_s <=> b.to_s}
  end
  
  def test_incorrect_fact_name
    begin
      StoreInventorySnapshotFact.define_aggregate :no_fact_by_this_name
      fail "Should have thrown ArgumentError"
    rescue ArgumentError => e
      # ok!
    end
  end
  
  def test_last_modified
    assert_not_nil PosRetailSalesTransactionFact.last_modified
  end
  
  def test_table_name
    assert_equal 'pos_retail_sales_transaction_facts', PosRetailSalesTransactionFact.table_name
  end
  
  def test_set_table_name
    PosRetailSalesTransactionFact.set_table_name(PosRetailSalesTransactionFact.table_name.singularize)
    assert_equal 'pos_retail_sales_transaction_fact', PosRetailSalesTransactionFact.table_name
    PosRetailSalesTransactionFact.set_table_name(PosRetailSalesTransactionFact.table_name.pluralize)
    assert_equal 'pos_retail_sales_transaction_facts', PosRetailSalesTransactionFact.table_name
  end
  
  def test_class_name
    assert_equal 'PosRetailSalesTransactionFact', PosRetailSalesTransactionFact.class_name('pos_retail_sales_transaction')
    assert_equal 'PosRetailSalesTransactionFact', PosRetailSalesTransactionFact.class_name(:pos_retail_sales_transaction)
    assert_equal 'PosRetailSalesTransactionFact', ActiveWarehouse::Fact.class_name('pos_retail_sales_transaction')
    assert_equal 'PosRetailSalesTransactionFact', ActiveWarehouse::Fact.class_name(:pos_retail_sales_transaction)
  end
  
  def test_class_for_name
    assert_equal PosRetailSalesTransactionFact, PosRetailSalesTransactionFact.class_for_name('pos_retail_sales_transaction')
    assert_equal PosRetailSalesTransactionFact, PosRetailSalesTransactionFact.class_for_name(:pos_retail_sales_transaction)
    assert_equal PosRetailSalesTransactionFact, ActiveWarehouse::Fact.class_for_name('pos_retail_sales_transaction')
    assert_equal PosRetailSalesTransactionFact, ActiveWarehouse::Fact.class_for_name(:pos_retail_sales_transaction)
  end
  
  def test_simple_aggregate_fields
    aggregate_fields = PosRetailSalesTransactionFact.aggregate_fields
    assert_not_nil aggregate_fields
    assert_equal 8, aggregate_fields.length
    assert aggregate_fields.find {|f| f.name == "sales_quantity"}
    assert aggregate_fields.find {|f| f.name == "sales_dollar_amount"}
    
    sales_quantity = PosRetailSalesTransactionFact.aggregate_field_for_name(:sales_quantity)
    assert_not_nil sales_quantity
    assert_equal :sum, sales_quantity.strategy_name
    
    assert ! PosRetailSalesTransactionFact.has_semiadditive_fact?
  end
  
  def test_complex_aggregate_fields
    aggregate_fields = StoreInventorySnapshotFact.aggregate_fields
    assert_not_nil aggregate_fields
    assert_equal 4, aggregate_fields.length
    
    quantity_on_hand = StoreInventorySnapshotFact.aggregate_field_for_name(:quantity_on_hand)
    assert_not_nil quantity_on_hand
    assert_equal :sum, quantity_on_hand.strategy_name
    assert quantity_on_hand.is_semiadditive?
    assert_equal DateDimension, quantity_on_hand.semiadditive_over
    
    assert StoreInventorySnapshotFact.has_semiadditive_fact?
  end
  
  def test_calculated_fields
    #calculated_fields[:]
  end
  
  def test_field_for_name
    assert_equal 'quantity_on_hand', StoreInventorySnapshotFact.field_for_name(:quantity_on_hand).name
    assert_equal 'gross_margin', PosRetailSalesTransactionFact.field_for_name(:gross_margin).name
  end
  
  def test_associations
    f = PosRetailSalesTransactionFact.new
    f.respond_to?(:date)
  end
  
  def test_prejoined_fields
    prejoined_fields = PosRetailSalesTransactionFact.prejoined_fields
    assert_not_nil prejoined_fields
    assert_equal 2, prejoined_fields.length
  end
  
  def test_prejoined_table_name
    assert_equal "prejoined_pos_retail_sales_transaction_facts", PosRetailSalesTransactionFact.prejoined_table_name
  end

  def test_dimension_relationships
    dimension_relationships = PosRetailSalesTransactionFact.dimension_relationships
    assert_not_nil dimension_relationships
    assert_equal 5, dimension_relationships.size
    dimension_names = dimension_relationships.collect{|k,v| k}.sort{|a,b| a.to_s <=> b.to_s}
    assert [:customer, :date, :product, :promotion, :store], dimension_names
  end
  
  def test_populate
    assert_nothing_raised do
      PosRetailSalesTransactionFact.populate
    end
  end
  
  def test_dimension_relationship
    assert DailySalesFact.belongs_to_relationship?(:date)
    assert DailySalesFact.has_and_belongs_to_many_relationship?(:product)
  end
  
end
