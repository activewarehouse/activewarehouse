require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::DataCell, ".new" do

	before(:each) do
		@fact_attribute = mock('fact_attribute')
		@column_dimension_value = "Something"
		@row_dimension_value = "2006"
		@value = "1.1"
		@raw_value = 1.1
		@cell = ActiveWarehouse::Report::DataCell.new(@column_dimension_value, @row_dimension_value, @fact_attribute, @raw_value, @value)
	end

	it "should have a row dimension value" do
		@cell.row_dimension_value.should == @row_dimension_value
	end
		
	it "should have a column dimension value" do
		@cell.column_dimension_value.should == @column_dimension_value
	end

	it "should have a fact attribute" do
		@cell.fact_attribute.should == @fact_attribute
	end

	it "should have a value" do
		@cell.value.should == @value
	end
	
	it "should have a raw value" do
		@cell.raw_value.should == @raw_value
	end
end