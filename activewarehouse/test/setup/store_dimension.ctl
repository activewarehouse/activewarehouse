pre_process :truncate, :target => :awunit, :table => 'store_dimension'

source :in, {
  :file => 'store_dimension.csv',
  :parser => :delimited,
  :skip_lines => 1,
  :store_locally => false,
},   
[ 
  :store_name,
  :store_number,
  :store_street_address,
  :store_city,
  :store_county,
  :store_state,
  :store_zip_code,
  :store_manager,
  :store_district,
  :store_region,
  :floor_plan_type,
  :photo_processing_type,
  :financial_service_type,
  :selling_square_footage,
  :total_square_footage,
  :first_open_date,
  :last_remodal_date
]

transform :selling_square_footage, :type, :type => :integer
transform :total_square_footage, :type, :type => :integer

destination :out, :type => :database, :target => :awunit, :table => 'store_dimension', :buffer_size => 0
