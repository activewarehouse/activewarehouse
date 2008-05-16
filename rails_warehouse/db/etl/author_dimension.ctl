# Control file for creating the author dimension from a Subversion log (in XML format)

#log_file = 'rails_log.xml'
log_file = 'input/aw_log.xml'
source :in, {
  :file => log_file,
  :parser => :sax
}, 
{
  :write_trigger => 'log/logentry',
  :fields => {
    :name => 'log/logentry/author'
  }
}

outfile = 'output/author_dimension.txt'
columns = [:id, :name]

destination :out, {
  :file => outfile,
  :unique => [:name]
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
  :table => 'author_dimension'
}