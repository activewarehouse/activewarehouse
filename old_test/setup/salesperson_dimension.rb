fields = {
  :name => :string,
  :region => :string,
  :sub_region => :string,
  :effective_date => :datetime,
  :expiration_date => :datetime
}
ActiveRecord::Base.connection.create_table :salesperson_dimension, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end