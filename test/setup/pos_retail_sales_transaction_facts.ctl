table = 'pos_retail_sales_transaction_facts'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :skip_lines => 1,
  :store_locally => false
}, 
[ 
  :date_id,
  :product_id,
  :store_id,
  :promotion_id,
  :customer_id,
  :pos_transaction_number,
  :sales_quantity,
  :sales_dollar_amount,
  :cost_dollar_amount,
  :gross_profit_dollar_amount,
]

transform :date_id, :type, :type => :integer
transform :product_id, :type, :type => :integer
transform :store_id, :type, :type => :integer
transform :promotion_id, :type, :type => :integer
transform :customer_id, :type, :type => :integer
transform :sales_quantity, :type, :type => :integer
transform :sales_dollar_amount, :type, :type => :decimal
transform :cost_dollar_amount, :type, :type => :decimal
transform :gross_profit_dollar_amount, :type, :type => :decimal

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0