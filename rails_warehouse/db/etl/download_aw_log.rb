#!/usr/bin/env ruby

puts "Retrieving ActiveWarehouse SVN Log"
log_file = File.dirname(__FILE__) + "/input/aw_log.xml"
`svn log svn://rubyforge.org/var/svn/activewarehouse --xml -v --revision 1:"HEAD" > #{log_file}`
puts "Log file retrieved and stored in #{log_file}"