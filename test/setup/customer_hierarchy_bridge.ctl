pre_process :truncate, :target => :awunit, :table => 'customer_hierarchy_bridge'

source :in, {
  :file => 'customer_hierarchy_bridge.csv',
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  :parent_id,
  :child_id,
  :levels_from_parent,
  :bottom_flag,
  :top_flag,
]

transform :parent_id, :type, :type => :integer
transform :child_id, :type, :type => :integer
transform :levels_from_parent, :type, :type => :integer

destination :out, :type => :database, :target => :awunit, :table => 'customer_hierarchy_bridge', :buffer_size => 0