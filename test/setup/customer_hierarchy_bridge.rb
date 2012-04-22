fields = {
  :parent_id => :integer,
  :child_id => :integer,
  :num_levels_from_parent => :integer,
  :bottom_flag => :string,
  :is_top => :string,
}
ActiveRecord::Base.connection.create_table :customer_hierarchy_bridge, :force => true do |t|
  fields.each do |name,type|
    t.column name, type
  end
end
