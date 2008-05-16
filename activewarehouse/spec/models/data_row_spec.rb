require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveWarehouse::Report::DataRow, ".new" do

	before(:each) do
		@cells = []
		@row = ActiveWarehouse::Report::DataRow.new('my_value', @cells)
	end

	it "should have a row dimension value" do
		@row.dimension_value.should == 'my_value'
	end

	it "should start with an empty cell array" do
	  @row.cells.should have(0).items
	end
end