table = 'salesperson_sales_facts'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :skip_lines => 1,
  :store_locally => false
}, 
[ 
  {:name => :date_id, :type => :integer},
  {:name => :salesperson_id, :type => :integer},
  {:name => :product_id, :type => :integer},
  {:name => :cost, :type => :integer}
]

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0