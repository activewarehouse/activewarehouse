module StandardAggregationAssertions
  def assert_query_success(object_to_query)
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :store, 
      :row_hierarchy_name => :region
    )
    values = results.values('Southeast', '2001')
    assert_equal 6, values.length, "Values length should be 6 but was #{values.length}"
    assert_equal 6, values['Sum of Sales Quantity']
    assert_in_delta 11.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2001 Southeast failed"
    assert_in_delta 5.50, values['Sum of Cost'], 0.01, "Sum of cost amount for 2001 Southeast failed"
    assert_in_delta 5.50, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2001 Southeast failed"
    assert_equal 6, values['Sales Quantity Count'], "Count of sales quantity for 2001 Southeast failed"
    assert_in_delta 1.83, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2001 Southeast failed"

    values = results.values('Southeast', '2002')
    assert_equal 6, values.length, "Values length should be 4 but was #{values.length}"
    assert_equal 2, values['Sum of Sales Quantity'], "Sum of sales quantity for 2002 Southeast failed"
    assert_in_delta 3.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2002 Southeast failed"
    assert_in_delta 2.00, values['Sum of Cost'], 0.01, "Sum of cost amount for 2002 Southeast failed"
    assert_in_delta 1.00, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2002 Southeast failed"
    assert_equal 2, values['Sales Quantity Count'], "Count of sales quantity for 2002 Southeast failed"
    assert_in_delta 1.5, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2002 Southeast failed"

    assert_equal(
      {'Sum of Sales Quantity' => 0,
       'Sum of Sales Amount' => 0,
       'Sum of Cost' => 0,
       'Sum of Gross Profit' => 0,
       'Sales Quantity Count' => 0,
       'Avg Sales Amount' => 0},
      results.values('Southeast','2003'), "Values for 2003 Southeast failed")
    
  end
  
  def assert_old_style_query_success(object_to_query)
    results = object_to_query.query(:date, :cy, :store, :region)
    values = results.values('Southeast', '2001')
    assert_equal 6, values.length, "Values length should be 6 but was #{values.length}"
    assert_equal 6, values['Sum of Sales Quantity']
    assert_in_delta 11.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2001 Southeast failed"
    assert_in_delta 5.50, values['Sum of Cost'], 0.01, "Sum of cost amount for 2001 Southeast failed"
    assert_in_delta 5.50, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2001 Southeast failed"
    assert_equal 6, values['Sales Quantity Count'], "Count of sales quantity for 2001 Southeast failed"
    assert_in_delta 1.83, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2001 Southeast failed"

    values = results.values('Southeast', '2002')
    assert_equal 6, values.length, "Values length should be 4 but was #{values.length}"
    assert_equal 2, values['Sum of Sales Quantity'], "Sum of sales quantity for 2002 Southeast failed"
    assert_in_delta 3.00, values['Sum of Sales Amount'], 0.01, "Sum of sales amount for 2002 Southeast failed"
    assert_in_delta 2.00, values['Sum of Cost'], 0.01, "Sum of cost amount for 2002 Southeast failed"
    assert_in_delta 1.00, values['Sum of Gross Profit'], 0.01, "Sum of gross profit for 2002 Southeast failed"
    assert_equal 2, values['Sales Quantity Count'], "Count of sales quantity for 2002 Southeast failed"
    assert_in_delta 1.5, values['Avg Sales Amount'], 0.01, "Avg of sales dollar amount for 2002 Southeast failed"

    assert_equal(
      {'Sum of Sales Quantity' => 0,
       'Sum of Sales Amount' => 0,
       'Sum of Cost' => 0,
       'Sum of Gross Profit' => 0,
       'Sales Quantity Count' => 0,
       'Avg Sales Amount' => 0},
      results.values('Southeast','2003'), "Values for 2003 Southeast failed")
      
    results = object_to_query.query(:date, :cy, :store, :region, nil, 0, 0, {}, {:order => 'Sum of Sales Quantity'})
  end

  def assert_query_drilldown_success(object_to_query)
    filters = {
      'date.calendar_year' => '2001',
      'date.calendar_quarter' => 'Q1',
      'date.calendar_month_name' => 'January',
      'date.calendar_week' => 'Week 1',
    }
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :store, 
      :row_hierarchy_name => :region, 
      :conditions => nil, 
      :cstage => 4, 
      :rstage => 0, 
      :filters => filters
    )
    values = results.values('Southeast', 'Monday')
    assert_equal 5, values['Sum of Sales Quantity'], "Assertion for sales quantity for 2001, Q1, January, Week 1, Monday in Southeast failed"
    assert_in_delta 10.00, values['Sum of Sales Amount'], 0.01, "Assertion for sales amount for 2001, Q1, January, Week 1, Monday in Southeast failed"
    assert_in_delta 5.00, values['Sum of Cost'], 0.01, "Assertion for cost amount for 2001, Q1, January, Week 1, Monday in Southeast failed"
  
    values = results.values('Southeast', 'Tuesday')
    assert_equal 1, values['Sum of Sales Quantity'], "Assertion for sales quantity for 2001, Q1, January, Week 1, Tuesday in Southeast failed"
    assert_in_delta 1.00, values['Sum of Sales Amount'], 0.01, "Assertion for sales amount for 2001, Q1, January, Week 1, Tuesday in Southeast failed"
    assert_in_delta 0.50, values['Sum of Cost'], 0.01, "Assertion for cost amount for 2001, Q1, January, Week 1, Tuesday in Southeast failed"
    assert_in_delta 0.50, values['Sum of Gross Profit'], 0.01, "Assertion for gross profit for 2001, Q1, January, Week 1, Tuesday in Southeast failed"
    assert_equal 1, values['Sales Quantity Count']
    assert_equal 1, values['Avg Sales Amount']
  
    assert_equal(
      {'Sum of Sales Quantity' => 0,
       'Sum of Sales Amount' => 0,
       'Sum of Cost' => 0,
       'Sum of Gross Profit' => 0,
       'Sales Quantity Count' => 0,
       'Avg Sales Amount' => 0},
      results.values('Southeast', 'Wednesday'))

    filters = {'date.calendar_year' => '2001', 'store.store_region' => 'Southeast'}
    
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :store, 
      :row_hierarchy_name => :region, 
      :conditions => nil, 
      :cstage => 1, 
      :rstage => 1, 
      :filters => filters
    )
    values = results.values('South Florida', 'Q1')
    assert_equal 6, values['Sum of Sales Quantity'], "Assertion for sales quantity for 2001, Q1 in South Florida in Southeast failed"
    assert_in_delta 11.00, values['Sum of Sales Amount'], 0.01, "Assertion for sales amount for 2001, Q1 in South Florida in Southeast failed"
    assert_in_delta 5.50, values['Sum of Cost'], 0.01, "Assertion for cost amount for 2001, Q1 in South Florida in Southeast failed"
    assert_in_delta 5.5, values['Sum of Gross Profit'], 0.01
    assert_equal 6, values['Sales Quantity Count']
    assert_in_delta 1.83, values['Avg Sales Amount'], 0.01
  end
  
  def assert_count_distinct_success(object_to_query)
    # use the dimension that has has_and_belongs_to_many relationship
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :product, 
      :row_hierarchy_name => :brand
    )
    
    values = results.values('Wholesome', '2006')
    assert_equal 1, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    values = results.values('Wholesome', '2007')    
    assert_equal 3, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    values = results.values('Delicious Brands', '2006')    
    assert_equal 1, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    values = results.values('Delicious Brands', '2007')    
    assert_equal 1, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    values = results.values('Yum Brands', '2006')    
    assert_equal 1, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    values = results.values('Yum Brands', '2007')    
    assert_equal 0, values['Num Sales']
    assert_nil values['daily_sales_facts_cost_sum']
    
    # use the dimensions that don't have has_and_belongs_to_many relationship
    results = object_to_query.query(
      :column_dimension_name => :date, 
      :column_hierarchy_name => :cy, 
      :row_dimension_name => :store, 
      :row_hierarchy_name => :region
    )
    
    values = results.values('Southeast', '2006')
    assert_equal 2, values['Num Sales']
    assert_equal 40, values['daily_sales_facts_cost_sum']
    
    values = results.values('Southeast', '2007')
    assert_equal 1, values['Num Sales']
    assert_equal 20, values['daily_sales_facts_cost_sum']

    values = results.values('Northeast', '2006')
    assert_equal 0, values['Num Sales']
    assert_equal 0, values['daily_sales_facts_cost_sum']
    
    values = results.values('Northeast', '2007')
    assert_equal 2, values['Num Sales']
    assert_equal 40, values['daily_sales_facts_cost_sum']
  end

end