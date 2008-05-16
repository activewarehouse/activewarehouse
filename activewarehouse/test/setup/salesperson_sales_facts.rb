fields = {
  :date_id => :integer,
  :product_id => :integer,
  :salesperson_id => :integer,
  :cost => :integer
}
conn = ActiveRecord::Base.connection
conn.create_table :salesperson_sales_facts, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end