source :in, {
  :file => 'scd/2.txt',
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
  :file => 'output/scd_test_type_1_2.txt',
  :scd => {
    :type => 1
  }
}, 
{
  :order => [:first_name, :last_name, :address, :city, :state, :zip_code]
}