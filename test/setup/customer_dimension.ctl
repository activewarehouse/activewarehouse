table = 'customer_dimension'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  :customer_name
]

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0