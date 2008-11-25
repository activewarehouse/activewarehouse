require 'rubygems'
require 'test/unit'
require 'shoulda'

require File.dirname(__FILE__) + '/../lib/activewarehouse'

ActiveRecord::Base.establish_connection(
  YAML::load_file(File.dirname(__FILE__) + '/database.yml')['test']
)

require File.dirname(__FILE__) + '/models/date_dimension' unless defined?(DateDimension)
require File.dirname(__FILE__) + '/models/store_dimension' unless defined?(StoreDimension)
require File.dirname(__FILE__) + '/models/order_fact' unless defined?(OrderFact)
require File.dirname(__FILE__) + '/models/sales_cube' unless defined?(SalesCube)