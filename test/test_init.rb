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