$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'pp'
require 'test/unit'
require 'activewarehouse'

raise "Missing required DB environment variable" unless ENV['DB']

require 'etl'

database_yml = File.dirname(__FILE__) + '/config/database.yml'
ETL::Engine.init(:config => database_yml)

ETL::Engine.logger = Logger.new('etl.log')
ETL::Engine.logger.level = Logger::ERROR


ActiveRecord::Base.establish_connection(:awunit)

require 'setup'
require 'populate'

require File.dirname(__FILE__) + '/test_init'

require 'standard_aggregation_assertions'
require 'hierarchical_dimension_aggregation_assertions'
require 'hierarchical_slowly_changing_dimension_aggregation_assertions'

#ActiveRecord::Base.logger.level = Logger::DEBUG
