# Example query at stage 0:0
SELECT
  date_dimension_calendar_year as calendar_year,
  store_dimension_store_region as store_region,
  pos_retail_sales_transaction_facts_sales_quantity as sales_quantity
FROM 
  regional_sales_cube_rollup 
WHERE 
  date_dimension_calendar_quarter is null and
  date_dimension_calendar_month_name is null and
  date_dimension_calendar_week is null and
  date_dimension_day_number_in_calendar_month is null and
  store_dimension_store_state is null and
  store_dimension_store_county is null and
  store_dimension_store_city is null and
  store_dimension_store_district is null
GROUP BY
  date_dimension_calendar_year,
  store_dimension_store_region;

# Example query at stage 1:0
SELECT
  date_dimension_calendar_quarter as calendar_quarter,
  store_dimension_store_region as store_region,
  pos_retail_sales_transaction_facts_sales_quantity as sales_quantity
FROM 
  regional_sales_cube_rollup 
WHERE 
  date_dimension_calendar_year = '2001' and
  date_dimension_calendar_month_name is null and
  date_dimension_calendar_week is null and
  date_dimension_day_number_in_calendar_month is null and
  store_dimension_store_state is null and
  store_dimension_store_county is null and
  store_dimension_store_city is null and
  store_dimension_store_district is null
GROUP BY
  date_dimension_calendar_quarter,
  store_dimension_store_region;
  
# Example query at stage 2:0
SELECT
  date_dimension_calendar_month_name as calendar_month_name,
  store_dimension_store_region as store_region,
  pos_retail_sales_transaction_facts_sales_quantity as sales_quantity
FROM 
  regional_sales_cube_rollup 
WHERE 
  date_dimension_calendar_week is null and
  date_dimension_day_number_in_calendar_month is null and
  store_dimension_store_state is null and
  store_dimension_store_county is null and
  store_dimension_store_city is null and
  store_dimension_store_district is null and
  date_dimension_calendar_year = '2001' and
  date_dimension_calendar_quarter = 'Q1'
GROUP BY
  date_dimension_calendar_month_name,
  store_dimension_store_region;

# Ignore
SELECT
 d1.calendar_year,
 d2.store_region
FROM 
  pos_retail_sales_transaction_facts f JOIN 
  date_dimension d1 on f.date_id = d1.id JOIN
  store_dimension d2 on f.store_id = d2.id;