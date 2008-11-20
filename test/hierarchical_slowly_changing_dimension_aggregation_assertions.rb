module HierarchicalSlowlyChangingDimensionAggregationAssertions

  def assert_hierarchical_scd_query_success(object_to_query)
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :salesperson, 
      :row_hierarchy_name => :name
    )
    values = results.values('Salesperson A', '2006')
    assert_equal 2, values.length, "Values length should be 2 but was #{values.length}"
    assert_equal 3, values['Num Sales'], "Num sales for 2006 Salesperson A should be 3"
    
    values = results.values('Salesperson B', '2006')
    assert_equal 2, values['Num Sales'], "Num sales for 2006 Salesperson B should be 2"
    
    values = results.values('Salesperson C', '2006')
    assert_equal 0, values['Num Sales'], "Num sales for 2006 Salesperson C should be 1"

    values = results.values('Salesperson A', '2007')
    assert_equal 2, values.length, "Values length should be 1 but was #{values.length}"
    assert_equal 3, values['Num Sales'], "Num sales for 2007 Salesperson A should be 3"
    
    values = results.values('Salesperson B', '2007')
    assert_equal 0, values['Num Sales'], "Num sales for 2007 Salesperson B should be 0"
    
    values = results.values('Salesperson C', '2007')
    assert_equal 0, values['Num Sales'], "Num sales for 2007 Salesperson C should be 1"
    
    values = results.values('Salesperson D', '2007')
    assert_equal 0, values['Num Sales'], "Num sales for 2007 Salesperson D should be 2"
  end
  
  def assert_scd_without_date(object_to_query)
    results = object_to_query.query(
      :column_dimension_name => :product, 
      :column_hierarchy_name => :brand, 
      :row_dimension_name => :salesperson, 
      :row_hierarchy_name => :name
    )
    values = results.values('Salesperson A', 'Delicious Brands')
    assert_equal 2, values.length, "Values length should be 2 but was #{values.length}"
    assert_equal 100, values['salesperson_sales_facts_cost_sum']
    assert_equal 5, values['Num Sales']
    
    values = results.values('Salesperson B', 'Delicious Brands')
    assert_equal 40, values['salesperson_sales_facts_cost_sum']
    assert_equal 2, values['Num Sales']
    
    values = results.values('Salesperson A', 'Yum Brands')
    assert_equal 20, values['salesperson_sales_facts_cost_sum']
    assert_equal 1, values['Num Sales']
  end

end