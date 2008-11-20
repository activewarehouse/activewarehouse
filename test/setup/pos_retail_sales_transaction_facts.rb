fields = {
  :date_id => :integer,
  :product_id => :integer,
  :store_id => :integer,
  :promotion_id => :integer,
  :customer_id => :integer,
  :pos_transaction_number => :string,
  :sales_quantity => :integer,
  :sales_dollar_amount => :float,
  :cost_dollar_amount => :float,
  :gross_profit_dollar_amount => :float
}
conn = ActiveRecord::Base.connection
conn.create_table :pos_retail_sales_transaction_facts, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end

