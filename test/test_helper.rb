$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rubygems'

# require 'rails_generator'
# Rails::Generator::Base.append_sources(
#   Rails::Generator::PathSource.new(:active_warehouse_test, "#{File.dirname(__FILE__)}/../generators/")
# )
# 
require 'rails'
require 'active_support'  
require 'active_record'
require 'action_view'
require 'pp'
require 'test/unit'

connection = (ENV['DB'] || 'native_mysql')
require "connection/#{connection}/connection"

require 'active_warehouse'

require 'etl'
ETL::Engine.logger = Logger.new('etl.log')
ETL::Engine.logger.level = Logger::ERROR

require 'setup'
require 'populate'

require File.dirname(__FILE__) + '/test_init'

require 'standard_aggregation_assertions'
require 'hierarchical_dimension_aggregation_assertions'
require 'hierarchical_slowly_changing_dimension_aggregation_assertions'

ActiveRecord::Base.logger.level = Logger::DEBUG