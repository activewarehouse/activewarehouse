require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::DataColumn, ".new" do

	before(:each) do
		@fact_attribute = mock('fact attribute')
		@column = ActiveWarehouse::Report::DataColumn.new('MyLabel','my_value', @fact_attribute)
	end

	it "should have a column dimension value" do
		@column.dimension_value.should == 'my_value'
	end
	
	it "should have a fact attribute" do
	  @column.fact_attribute.should == @fact_attribute
	end
	
	it "should have a label" do
	  @column.label.should == "MyLabel"
	end

end