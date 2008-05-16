# Change Type Dimension Control file

source :in, {
  :file => 'input/change_type_dimension.source.txt',
  :parser => :delimited
}, 
[ 
  :change_type_code,
  :change_type_description
]

outfile = 'output/change_type_dimension.txt'
columns = [:id, :change_type_code, :change_type_description]
destination :out, {
  :file => outfile
},
{
  :order => columns,
  :virtual => {
    :id => :surrogate_key
  }
}

post_process :bulk_import, {
  :file => outfile,
  :truncate => true,
  :columns => columns,
  :target => :warehouse,
  :table => 'change_type_dimension'
}