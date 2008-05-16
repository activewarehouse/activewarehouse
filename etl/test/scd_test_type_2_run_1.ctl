source :in, {
  :file => 'scd/1.txt',
  :parser => :delimited
},
[
  :first_name,
  :last_name,
  :address,
  :city,
  :state,
  :zip_code
]

destination :out, {
  :file => 'output/scd_test_type_2_1.txt',
  :natural_key => [:first_name, :last_name],
  :scd => {
    :type => 2,
    :dimension_target => :data_warehouse,
    :dimension_table => 'person_dimension'
  },
  :scd_fields => [:address, :city, :state, :zip_code]
}, 
{
  :order => [
    :first_name, :last_name, :address, :city, :state, :zip_code, :effective_date, :end_date
  ]
}

post_process :bulk_import, {
  :file => 'output/scd_test_type_2_1.txt',
  :truncate => true,
  :target => :data_warehouse,
  :table => 'person_dimension'
}