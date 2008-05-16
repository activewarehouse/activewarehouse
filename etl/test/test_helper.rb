$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__))

require 'test/unit'
require 'pp'
require 'etl'
require 'flexmock/test_unit'

ETL::Engine.init(:config => File.dirname(__FILE__) + '/database.yml')
ETL::Engine.logger = Logger.new(STDOUT)
ETL::Engine.logger.level = Logger::FATAL

require 'connection/native_mysql/connection'
ActiveRecord::Base.establish_connection :operational_database

ETL::Execution::Job.delete_all
ETL::Execution::Record.delete_all

require 'mocks/mock_source'
require 'mocks/mock_destination'

# shortcut to launch a ctl file
def process(file)
  Engine.process(File.join(File.dirname(__FILE__), file))
end
