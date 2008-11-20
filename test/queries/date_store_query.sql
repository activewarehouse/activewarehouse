# Top level
SELECT
  date_dimension.calendar_year AS calendar_year,
  store_dimension.store_region AS store_region,
  sum(pos_retail_sales_transaction_facts.sales_quantity) AS sales_quantity,
  sum(pos_retail_sales_transaction_facts.sales_dollar_amount) AS sales_dollar_amount
FROM
  pos_retail_sales_transaction_facts JOIN
  date_dimension on pos_retail_sales_transaction_facts.date_id = date_dimension.id JOIN
  store_dimension on pos_retail_sales_transaction_facts.store_id = store_dimension.id JOIN
  product_dimension on pos_retail_sales_transaction_facts.product_id = product_dimension.id
GROUP BY
  date_dimension.calendar_year,
  store_dimension.store_region;
  
-- Drill down on calendar (stage 1)
SELECT
  date_dimension.calendar_quarter AS calendar_quarter,
  store_dimension.store_region AS store_region,
  sum(pos_retail_sales_transaction_facts.sales_quantity) AS sales_quantity,
  sum(pos_retail_sales_transaction_facts.sales_dollar_amount) AS sales_dollar_amount
FROM
  pos_retail_sales_transaction_facts JOIN
  date_dimension on pos_retail_sales_transaction_facts.date_id = date_dimension.id JOIN
  store_dimension on pos_retail_sales_transaction_facts.store_id = store_dimension.id JOIN
  product_dimension on pos_retail_sales_transaction_facts.product_id = product_dimension.id
WHERE
  date_dimension.calendar_year = 2006
GROUP BY
  date_dimension.calendar_quarter,
  store_dimension.store_region;
  
-- Drill down on calendar (stage 2)
SELECT
  date_dimension.calendar_month_name AS calendar_month_name,
  store_dimension.store_region AS store_region,
  sum(pos_retail_sales_transaction_facts.sales_quantity) AS sales_quantity,
  sum(pos_retail_sales_transaction_facts.sales_dollar_amount) AS sales_dollar_amount
FROM
  pos_retail_sales_transaction_facts JOIN
  date_dimension on pos_retail_sales_transaction_facts.date_id = date_dimension.id JOIN
  store_dimension on pos_retail_sales_transaction_facts.store_id = store_dimension.id JOIN
  product_dimension on pos_retail_sales_transaction_facts.product_id = product_dimension.id
WHERE
  date_dimension.calendar_year = 2006 AND
  date_dimension.calendar_quarter = 'Q1'
GROUP BY
  date_dimension.calendar_month_name,
  store_dimension.store_region;