# Control file for creating the file revision facts from a Subversion log (in XML format)

#log_file = 'rails_log.xml'
log_file = 'input/aw_log.xml'
source :in, {
  :file => log_file,
  :parser => :sax
}, 
{
  :write_trigger => 'log/logentry/paths/path',
  :fields => {
    :revision => 'log/logentry[revision]',
    :date_id => 'log/logentry/date',
    :author_id => 'log/logentry/author',
    :file_id => 'log/logentry/paths/path',
    :change_type_id => 'log/logentry/paths/path[action]'
  }
}

transform :date_id, :string_to_date
transform :date_id, :foreign_key_lookup, {
  :resolver => SQLResolver.new('date_dimension', 'sql_date_stamp', :warehouse)
}
transform :author_id, :foreign_key_lookup, {
  :resolver => SQLResolver.new('author_dimension', 'name', :warehouse)
}
transform :change_type_id, :foreign_key_lookup, {
  :resolver => SQLResolver.new('change_type_dimension', 'change_type_code', :warehouse)
}
transform :file_id, :foreign_key_lookup, {
  :resolver => SQLResolver.new('file_dimension', 'path', :warehouse)
}

outfile = 'output/file_revision_facts.txt'
columns = [:date_id,:file_id,:change_type_id,:author_id,:revision,:file_changed]
destination :out, {
  :file => outfile
}, 
{
  :order => columns,
  :virtual => {
    :file_changed => 1
  }
}

post_process :bulk_import, {
  :file => outfile,
  :truncate => true,
  :columns => columns,
  :target => :warehouse,
  :table => 'file_revision_facts'
}