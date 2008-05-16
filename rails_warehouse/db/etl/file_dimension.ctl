# Control file for creating the file dimension from a Subversion log (in XML format)

# Determines the file type of the path. The 
def file_type(path)
  file_type_map = {
    '.rb' => 'Ruby',
    '.rhtml' => 'ERb',
    '.rjs' => 'RJS',
    '.rake' => 'Ruby Make File',
    '.html' => 'HTML',
    '.js' => 'JavaScript',
    '.css' => 'Cascading Style Sheet',
    '.cgi' => 'CGI',
    '.fcgi' => 'Fast CGI',
    '.gif' => 'GIF Image',
    '.jpeg' => 'JPEG Image',
    '.jpg' => 'JPEG Image',
    '.png' => 'PNG Image',
    '.sql' => 'SQL'
  }
  if File.directory?(path)
    'Directory'
  else
    file_type_map[File.extname(path)] || 'Unknown'
  end
end

log_file = 'input/aw_log.xml'
source :in, {
  :file => log_file,
  :parser => :sax
}, 
{
  :write_trigger => 'log/logentry/paths/path',
  :fields => {
    :path => 'log/logentry/paths/path'
  }
}

copy :path, :directory
copy :path, :file_name
copy :path, :file_base
copy :path, :file_type
copy :path, :extension
copy :path, :framework

transform(:directory){ |n,v,r| File.dirname(v) }
transform(:file_name){ |n,v,r| File.basename(v) }
transform(:file_base){ |n,v,r| File.basename(v, File.extname(v)) }
transform(:file_type){ |n,v,r| file_type(v) }
transform(:extension){ |n,v,r| File.extname(v).blank? ? 'None' : File.extname(v) }
transform(:framework){ |n,v,r| 'Unknown' }

outfile = 'output/file_dimension.txt'
columns = [:id,:path,:directory,:file_name,:file_base,:file_type,:extension,:framework]
destination :out, {
  :file => outfile,
  :unique => [:path]
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
  :table => 'file_dimension'
}