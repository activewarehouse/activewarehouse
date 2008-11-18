require File.dirname(__FILE__) + '/test_init'

require 'setup'
require 'populate'

require 'standard_aggregation_assertions'
require 'hierarchical_dimension_aggregation_assertions'
require 'hierarchical_slowly_changing_dimension_aggregation_assertions'

ActiveRecord::Base.logger.level = Logger::DEBUG