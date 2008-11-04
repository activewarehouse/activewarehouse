table = 'store_inventory_snapshot_facts'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  {:name => :date_id, :type => :integer},
  {:name => :product_id, :type => :integer},
  {:name => :store_id, :type => :integer},
  {:name => :quantity_on_hand, :type => :integer},
  {:name => :quantity_sold, :type => :integer},
  {:name => :dollar_value_at_cost, :type => :double},
  {:name => :dollar_value_at_latest_selling_price, :type => :double},
]

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0