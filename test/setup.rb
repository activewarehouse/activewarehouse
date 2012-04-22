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
  ETL::Engine.init :config => File.dirname(__FILE__) + '/config/database.yml'
end