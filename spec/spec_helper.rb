$:.unshift(File.dirname(__FILE__) + '/../test')
require 'test_init'
require 'spec'

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
	@report = mock('report')
	@cube = mock('cube')
	query_result = mock('query_result')
	@cube.stub!(:query).and_return(query_result)
	eval("class CustomerFact < ActiveWarehouse::Fact;  end")
	eval("class EventDateDimension < ActiveWarehouse::Dimension; define_hierarchy :year_hierarchy, [:year, :month, :day]; end")
	
	@field1 = mock('field1')
	@field1.stub!(:label).and_return("Field 1")
	@field1.stub!(:name).and_return("field1")
	CustomerFact.stub!(:field_for_name).and_return(@field1)
	@report.stub!(:fact_class).and_return(CustomerFact)
	@report.stub!(:fact_attributes).and_return([:field1,:field2])
	
	@report.stub!(:cube).and_return(@cube)
	@report.stub!(:conditions).and_return({})
	@report.stub!(:column_dimension_class).and_return(EventDateDimension)
	@report.stub!(:column_dimension_name).and_return("event_date_dimension")
	@report.stub!(:column_hierarchy).and_return(:year_hierarchy)
	@report.stub!(:column_stage).and_return(1)
	@report.stub!(:column_filters).and_return({})
	@report.stub!(:column_param_prefix).and_return('c')
	@report.stub!(:format).and_return({})
	@report.stub!(:html_params).and_return({})			
	@report.stub!(:row_dimension_class).and_return(EventDateDimension)
	@report.stub!(:row_dimension_name).and_return("event_date_dimension")
	@report.stub!(:row_hierarchy).and_return(:year_hierarchy)
	@report.stub!(:row_stage).and_return(1)
	@report.stub!(:row_filters).and_return({})
	@report.stub!(:row_param_prefix).and_return('r')	
	@report
end

ActiveRecord::Base.logger.level = Logger::DEBUG


