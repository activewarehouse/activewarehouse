fields = {
  :customer_name => :string,
}
ActiveRecord::Base.connection.create_table :customer_dimension, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end