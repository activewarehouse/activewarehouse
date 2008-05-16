module HierarchicalDimensionAggregationAssertions
  def assert_hierarchical_query_success(object_to_query)
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :customer, 
      :row_hierarchy_name => :customer_name
    )
    values = results.values('Bob Smith', '2001')
    assert_equal 8, values.length, "Values length should be 8 but was #{values.length}"
    assert_equal 10, values['Sum of Sales Quantity']
    assert_equal 2, values['Sum of Sales Quantity Self']
    assert_equal 5, values['Sum of Sales Quantity Me and Immediate children']
    assert_in_delta 25.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2001 Bob Smith failed"
    assert_in_delta 10.00, values['Sum of Cost'], 0.01, "Sum of cost amount for 2001 Bob Smith failed"
    assert_in_delta 15.00, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2001 Bob Smith failed"
    assert_equal 10, values['Sales Quantity Count'], "Count of sales quantity for 2001 Bob Smith failed"
    assert_in_delta 2.5, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2001 Bob Smith failed"
    
    values = results.values('Bob Smith', '2002')    
    assert_equal 8, values.length, "Values length should be 8 but was #{values.length}"
    assert_equal 2, values['Sum of Sales Quantity']
    assert_equal 0, values['Sum of Sales Quantity Self']
    assert_equal 0, values['Sum of Sales Quantity Me and Immediate children']
    assert_in_delta 3.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2002 Bob Smith failed"
    assert_in_delta 2.00, values['Sum of Cost'], 0.01, "Sum of cost amount for 2002 Bob Smith failed"
    assert_in_delta 1.00, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2002 Bob Smith failed"
    assert_equal 2, values['Sales Quantity Count'], "Count of sales quantity for 2002 Bob Smith failed"
    assert_in_delta 1.5, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2002 Bob Smith failed"
  end

  def assert_hierarchical_query_drilldown_success(object_to_query)
    filters = {
      'date.calendar_year' => '2001',
      'date.calendar_quarter' => 'Q1',
      'date.calendar_month_name' => 'January',
      'date.calendar_week' => 'Week 1',
    }
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :customer, 
      :row_hierarchy_name => :customer_name,
      :cstage => 4, 
      :rstage => 0, 
      :filters => filters
    )
    values = results.values('Bob Smith', 'Monday')
    assert_equal 7, values['Sum of Sales Quantity']
    assert_equal 1, values['Sum of Sales Quantity Self']
    assert_equal 3, values['Sum of Sales Quantity Me and Immediate children']
    assert_in_delta 16.00, values['Sum of Sales Amount'], 0.01, "Assertion for sales amount for 2001, Q1, January, Week 1, Monday for Bob Smith failed"
    assert_in_delta 7.50, values['Sum of Cost'], 0.01, "Assertion for cost amount for 2001, Q1, January, Week 1, Monday for Bob Smith failed"
    assert_in_delta 8.50, values['Sum of Gross Profit'], 0.01, "Assertion for gross profit for 2001, Q1, January, Week 1, Monday for Bob Smith failed"

    values = results.values('Bob Smith', 'Tuesday')
    assert_equal 3, values['Sum of Sales Quantity']
    assert_equal 1, values['Sum of Sales Quantity Self']
    assert_equal 2, values['Sum of Sales Quantity Me and Immediate children']
    assert_in_delta 9.00, values['Sum of Sales Amount'], 0.01, "Assertion for sales amount for 2001, Q1, January, Week 1, Monday for Bob Smith failed"
    assert_in_delta 2.50, values['Sum of Cost'], 0.01, "Assertion for cost amount for 2001, Q1, January, Week 1, Monday for Bob Smith failed"
    assert_in_delta 6.50, values['Sum of Gross Profit'], 0.01, "Assertion for gross profit for 2001, Q1, January, Week 1, Monday for Bob Smith failed"
    assert_equal 3, values['Sales Quantity Count']
    assert_in_delta 3, values['Avg Sales Amount'], 0.01

    assert_equal(
      {'Sum of Sales Quantity' => 0,
       'Sum of Sales Quantity Self' => 0,
       'Sum of Sales Quantity Me and Immediate children' => 0,
       'Sum of Sales Amount' => 0,
       'Sum of Cost' => 0,
       'Sum of Gross Profit' => 0,
       'Sales Quantity Count' => 0,
       'Avg Sales Amount' => 0},
      results.values('Bob Smith', 'Wednesday'))

    filters = {'date.calendar_year' => '2001'}
    
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :customer, 
      :row_hierarchy_name => :customer_name, 
      :conditions => nil, 
      :cstage => 1, 
      :rstage => 1, 
      :filters => filters
    )
    values = results.values('Jane Doe', 'Q1')
    assert_equal 6, values['Sum of Sales Quantity']
    assert_equal 2, values['Sum of Sales Quantity Self']
    assert_equal 4, values['Sum of Sales Quantity Me and Immediate children']
    assert_in_delta 15.00, values['Sum of Sales Amount'], 0.01
    assert_in_delta 7.00, values['Sum of Cost'], 0.01
    assert_in_delta 8.0, values['Sum of Gross Profit'], 0.01
    assert_equal 6, values['Sales Quantity Count']
    assert_in_delta 2.5, values['Avg Sales Amount'], 0.01

    assert_equal(
      {'Sum of Sales Quantity' => 0,
       'Sum of Sales Quantity Self' => 0,
       'Sum of Sales Quantity Me and Immediate children' => 0,
       'Sum of Sales Amount' => 0,
       'Sum of Cost' => 0,
       'Sum of Gross Profit' => 0,
       'Sales Quantity Count' => 0,
       'Avg Sales Amount' => 0},
      results.values('Jimmy Dean', 'Q1'))

    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :customer, 
      :row_hierarchy_name => :customer_name, 
      :conditions => nil, 
      :cstage => 1, 
      :rstage => 2, 
      :filters => filters
    )
    values = results.values('Jimmy Dean', 'Q1')    
    assert_equal 3, values['Sum of Sales Quantity']
    assert_equal 1, values['Sum of Sales Quantity Self']
    assert_equal 3, values['Sum of Sales Quantity Me and Immediate children']    
    assert_in_delta 8.00, values['Sum of Sales Amount'], 0.01
    assert_in_delta 4.00, values['Sum of Cost'], 0.01
    assert_in_delta 4.0, values['Sum of Gross Profit'], 0.01
    assert_equal 3, values['Sales Quantity Count']
    assert_in_delta 2.66, values['Avg Sales Amount'], 0.01
  end
end
