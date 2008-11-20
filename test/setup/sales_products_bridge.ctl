awunit = ActiveRecord::Base.configurations['awunit'].symbolize_keys
table = 'sales_products_bridge'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :skip_lines => 1,
  :store_locally => false
}, 
[ 
  {:name => :sale_id, :type => :integer},
  {:name => :product_id, :type => :integer}
]

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0
