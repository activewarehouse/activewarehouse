fields = {
  :sale_id => :integer,
  :product_id => :integer
}
conn = ActiveRecord::Base.connection
conn.create_table :sales_products_bridge, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end
