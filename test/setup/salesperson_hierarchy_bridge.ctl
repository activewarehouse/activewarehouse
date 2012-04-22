table = 'salesperson_hierarchy_bridge'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => 'salesperson_hierarchy_bridge.csv',
  :parser => :csv,
  :store_locally => false
}, 
[ 
  :parent_id,
  :child_id,
  :num_levels_from_parent,
  :effective_date,
  :expiration_date,
  :bottom_flag,
  :is_top,
]

transform :parent_id, :type, :type => :integer
transform :child_id, :type, :type => :integer
transform :num_levels_from_parent, :type, :type => :integer
transform :effective_date, :type, :type => :date
transform :expiration_date, :type, :type => :date

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0
