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
  :file => 'output/scd_test_type_1_1.txt'
}, 
{
  :order => [:first_name, :last_name, :address, :city, :state, :zip_code]
}