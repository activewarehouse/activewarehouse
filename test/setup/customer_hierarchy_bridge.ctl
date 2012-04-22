pre_process :truncate, :target => :awunit, :table => 'customer_hierarchy_bridge'

source :in, {
  :file => 'customer_hierarchy_bridge.csv',
  :parser => :csv,
  :store_locally => false
}, 
[ 
  :parent_id,
  :child_id,
  :num_levels_from_parent,
  :bottom_flag,
  :is_top,
]

transform :parent_id, :type, :type => :integer
transform :child_id, :type, :type => :integer
transform :num_levels_from_parent, :type, :type => :integer

destination :out, :type => :database, :target => :awunit, :table => 'customer_hierarchy_bridge', :buffer_size => 0
