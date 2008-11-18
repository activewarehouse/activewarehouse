table = 'salesperson_dimension'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  :name,
  :region,
  :sub_region,
  {:name => :effective_date, :type => :datetime},
  {:name => :expiration_date, :type => :datetime}
]

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0