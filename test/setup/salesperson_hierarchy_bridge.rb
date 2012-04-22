fields = {
  :parent_id => :integer,
  :child_id => :integer,
  :num_levels_from_parent => :integer,
  :effective_date => :date,
  :expiration_date => :date,
  :bottom_flag => :string,
  :is_top => :string,
}
ActiveRecord::Base.connection.create_table :salesperson_hierarchy_bridge, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end
