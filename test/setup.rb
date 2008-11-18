require 'rubygems'
require File.dirname(__FILE__) + '/../lib/activewarehouse'
ActiveRecord::Base.establish_connection(
  YAML::load_file(File.dirname(__FILE__) + '/database.yml')['test']
)
require File.dirname(__FILE__) + '/schema'