$:.unshift(File.dirname(__FILE__) + '/../test')

require 'activewarehouse'

require 'rspec'
require 'rubygems'
#require 'ruby-debug'
#require 'pry'

#raise "Missing required DB environment variable" unless ENV['DB']

database_yml = File.dirname(__FILE__) + '/../test/config/database.yml'
database_config = YAML::load(ERB.new(IO.read(database_yml)).result)
ActiveRecord::Base.configurations = database_config

file = open('activerecord.log', 'w')
ActiveRecord::Base.logger = Logger.new(file)
ActiveRecord::Base.logger.level = Logger::DEBUG
ActiveRecord::Base.establish_connection :awunit

require 'models/date_dimension'
require 'models/store_dimension'
require 'models/product_dimension'
require 'models/promotion_dimension'
require 'models/pos_retail_sales_transaction_fact'
require 'models/regional_sales_cube'
require 'models/multi_dimensional_regional_sales_cube'
require 'models/customer_sales_cube'

require 'models/salesperson_dimension'
require 'models/salesperson_hierarchy_bridge'
require 'models/salesperson_sales_fact'
require 'models/salesperson_sales_cube'

require 'models/store_inventory_snapshot_fact'
require 'models/store_inventory_snapshot_cube'

require 'models/customer_dimension'
require 'models/customer_hierarchy_bridge'

require 'models/daily_sales_fact'
require 'models/daily_sales_cube'


def stub_report
  report = double('report')
  cube = double('cube')
  query_result = double('query_result')
  allow(cube).to receive(:query_row_and_column) { query_result }
  eval("class CustomerFact < ActiveWarehouse::Fact;  end")
  eval("class EventDateDimension < ActiveWarehouse::Dimension; define_hierarchy :year_hierarchy, [:year, :month, :day]; end")

  field1 = double('field1')
  allow(field1).to receive(:label) { "Field 1" }
  allow(field1).to receive(:name) { "field1" }
  allow(CustomerFact).to receive(:field_for_name) { field1 }
  allow(report).to receive(:fact_class) { CustomerFact }
  allow(report).to receive(:fact_attributes) { [:field1,:field2] }

  allow(report).to receive(:cube) { cube }
  allow(report).to receive(:conditions) { {} }
  allow(report).to receive(:column_dimension_class) { EventDateDimension }
  allow(report).to receive(:column_dimension_name) { "event_date_dimension" }
  allow(report).to receive(:column_hierarchy) { :year_hierarchy }
  allow(report).to receive(:column_stage) { 1 }
  allow(report).to receive(:column_filters) { {} }
  allow(report).to receive(:column_param_prefix) { 'c' }
  allow(report).to receive(:format) { {} }
  allow(report).to receive(:html_params) { {} }
  allow(report).to receive(:row_dimension_class) { EventDateDimension }
  allow(report).to receive(:row_dimension_name) { "event_date_dimension" }
  allow(report).to receive(:row_hierarchy) { :year_hierarchy }
  allow(report).to receive(:row_stage) { 1 }
  allow(report).to receive(:row_filters) { {} }
  allow(report).to receive(:row_param_prefix) { 'r' }
  report
end


RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end

ActiveRecord::Base.logger.level = Logger::DEBUG


