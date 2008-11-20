table = 'product_dimension'
pre_process :truncate, :target => :awunit, :table => table

source :in, {
  :file => "#{table}.csv",
  :parser => :delimited,
  :store_locally => false
}, 
[ 
  :product_description,
  :sku_number,
  :brand_description,
  :category_description,
  :department_description,
  :package_type_description,
  :package_size,
  :fat_content,
  :weight,
  :weight_units_of_measure,
  :storage_type,
  :shelf_life_type,
  :shelf_width,
  :shelf_height,
  :shelf_depth,
  {:name => :latest_version, :type => :boolean},
  {:name => :effective_date, :type => :datetime},
  {:name => :expiration_date, :type => :datetime}
]

transform :sku_number, :type, :type => :integer
transform :weight, :type, :type => :integer

destination :out, :type => :database, :target => :awunit, :table => table, :buffer_size => 0