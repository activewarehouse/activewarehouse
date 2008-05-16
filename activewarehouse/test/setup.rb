#etl_home = ENV['ETL_HOME'] || raise("You must specify your ETL_HOME. Example: rake ETL_HOME=/path/to/etl/")
#puts "Using ETL_HOME: #{etl_home}"

#require("#{etl_home}/lib/etl")

unless Kernel.respond_to?(:gem)
  Kernel.send :alias_method, :gem, :require_gem
end
gem 'activewarehouse-etl'
require 'etl'

ETL::Engine.logger = Logger.new('etl.log')
ETL::Engine.logger.level = Logger::ERROR

require 'setup/date_dimension'
require 'setup/store_dimension'
require 'setup/customer_dimension'
require 'setup/customer_hierarchy_bridge'
require 'setup/product_dimension'
require 'setup/promotion_dimension'
require 'setup/pos_retail_sales_transaction_facts'
require 'setup/store_inventory_snapshot_facts'
require 'setup/salesperson_dimension'
require 'setup/salesperson_hierarchy_bridge'
require 'setup/salesperson_sales_facts'
require 'setup/sales_products_bridge'
require 'setup/daily_sales_facts'

ActiveRecord::Base.connection.reconnect!
puts "Migrating ActiveWarehouse"
migration_directory = File.join(File.dirname(__FILE__), '../db/migrations')
ActiveWarehouse::Migrator.migrate(migration_directory, 0)
ActiveWarehouse::Migrator.migrate(migration_directory, nil)

if ETL::Engine.respond_to?(:init)
  ETL::Engine.init :config => File.dirname(__FILE__) + '/database.yml'
end