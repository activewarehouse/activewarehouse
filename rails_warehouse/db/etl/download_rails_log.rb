#!/usr/bin/env ruby

puts "Retrieving Rails SVN Log"
log_file = File.dirname(__FILE__) + "/input/rails_log.xml"
`svn log http://dev.rubyonrails.org/svn/rails/trunk --xml -v --revision 1:"HEAD" > #{log_file}`
puts "Log file retrieved and stored in #{log_file}"